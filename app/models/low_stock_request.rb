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

  REVIEW_TRANSITIONS = {
    "pending" => %w[approved rejected],
    "rejected" => %w[approved],
    "approved" => %w[completed]
  }.freeze

  def review!(reviewer, decision, note: nil)
    decision = decision.to_s
    unless %w[approved rejected completed].include?(decision)
      raise ArgumentError, "invalid decision: #{decision}"
    end
    unless REVIEW_TRANSITIONS.fetch(status, []).include?(decision)
      raise ArgumentError, "request is already #{status}"
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

  def mark_completed! = update!(status: :completed)

  def suggested_restock_quantity = ingredient.suggested_reorder_quantity

  private

  def create_restock_task!
    open_task = RestockTask.open.find_by(ingredient_id: ingredient_id)
    if open_task
      open_task.update!(low_stock_request: self) if open_task.low_stock_request_id.nil?
      return
    end

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
