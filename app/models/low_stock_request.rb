class LowStockRequest < ApplicationRecord
  belongs_to :user
  belongs_to :ingredient
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :status,  { pending: 0, approved: 1, rejected: 2, completed: 3 }, default: :pending
  enum :urgency, { low: 0, normal: 1, high: 2 }, default: :normal

  scope :recent, -> { order(created_at: :desc) }
  scope :open, -> { where(status: %i[pending approved]) }
  scope :by_status, ->(status) { where(status: status) if status.present? && statuses.key?(status) }
  scope :by_urgency, ->(urgency) { where(urgency: urgency) if urgency.present? && urgencies.key?(urgency) }

  validates :note, length: { maximum: 500 }, allow_blank: true
  validate  :requester_must_be_kitchen_staff

  def review!(reviewer, decision, note: nil)
    decision = decision.to_s
    unless %w[approved rejected completed].include?(decision)
      raise ArgumentError, "invalid decision: #{decision}"
    end
    if decision == "rejected" && note.blank?
      raise ArgumentError, "rejection reason is required"
    end

    transaction do
      update!(status: decision, reviewed_by: reviewer, reviewed_at: Time.zone.now,
              review_note: note.presence)
      create_restock_task! if approved?
    end
  end

  def suggested_restock_quantity
    threshold = ingredient.low_stock_threshold.to_d
    suggested = threshold - ingredient.current_quantity.to_d
    suggested = threshold if suggested <= 0
    suggested = 1.to_d if suggested <= 0
    suggested
  end

  private

  def create_restock_task!
    return if RestockTask.open.exists?(ingredient_id: ingredient_id)

    RestockTask.create!(
      ingredient: ingredient,
      quantity: suggested_restock_quantity,
      source: :request,
      status: :pending,
      low_stock_request: self,
      note: "Approved from low stock request ##{id}"
    )
  end

  def requester_must_be_kitchen_staff
    return if user.blank?
    return if user.kitchen_staff? || user.admin?

    errors.add(:user, "must be kitchen staff")
  end
end
