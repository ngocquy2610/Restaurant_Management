class WasteReport < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? && statuses.key?(status) }

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :verified_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :reason, presence: true, length: { maximum: 500 }

  validate :verified_quantity_not_over_reported

  # Approve: create a WASTE transaction, deduct stock, optionally open a restock task.
  # Reject: requires a reason and leaves stock untouched.
  def review!(reviewer, decision, verified_quantity: nil, note: nil, create_restock_task: false)
    decision = decision.to_s
    approved = decision == "approved"
    verified = verified_quantity.presence

    raise ArgumentError, "invalid decision: #{decision}" unless approved || decision == "rejected"
    raise ArgumentError, "report already reviewed" unless pending?
    raise ArgumentError, "rejection reason is required" if !approved && note.blank?

    transaction do
      # Persist the decision first so validations run before any stock movement.
      update!(
        status:            decision,
        reviewed_by:       reviewer,
        reviewed_at:       Time.zone.now,
        verified_quantity: approved ? (verified || quantity) : nil,
        review_note:       note.presence
      )

      if approved
        apply_waste_to_stock!(reviewer, (verified || quantity).to_d)
        create_waste_restock_task! if create_restock_task
      end
    end
  end

  def suggested_restock_quantity
    threshold = ingredient.low_stock_threshold.to_d
    suggested = threshold - ingredient.reload.current_quantity.to_d
    suggested = threshold if suggested <= 0
    suggested = 1.to_d  if suggested <= 0
    suggested
  end

  private

  def apply_waste_to_stock!(reviewer, quantity)
    reference = "waste_report:#{id}"
    return if StockTransaction.exists?(reference: reference, transaction_type: :waste)

    StockService.waste(
      ingredient: ingredient,
      quantity:   quantity,
      user:       reviewer,
      reason:     "Waste report ##{id}: #{reason}",
      reference:  reference
    )
  end

  def create_waste_restock_task!
    return if RestockTask.open.exists?(ingredient_id: ingredient_id)

    RestockTask.create!(
      ingredient:   ingredient,
      quantity:     suggested_restock_quantity,
      source:       :waste,
      status:       :pending,
      waste_report: self,
      note:         "Created from waste report ##{id}"
    )
  end

  def verified_quantity_not_over_reported
    return if verified_quantity.blank? || quantity.blank?
    return if verified_quantity.to_d <= quantity.to_d

    errors.add(:verified_quantity, "cannot exceed reported quantity")
  end
end
