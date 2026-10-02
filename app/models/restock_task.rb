class RestockTask < ApplicationRecord
  belongs_to :ingredient
  belongs_to :low_stock_request, optional: true
  belongs_to :waste_report,      optional: true

  enum :status, { pending: 0, in_progress: 1, completed: 2, cancelled: 3 }, default: :pending
  enum :source, { auto: 0, request: 1, waste: 2 }, default: :auto

  scope :open,   -> { where(status: %i[pending in_progress]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? && statuses.key?(status) }

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  validate :source_reference_consistency

  def complete!
    update!(status: :completed)
  end

  private

  def source_reference_consistency
    if request? && low_stock_request.blank?
      errors.add(:low_stock_request, "is required when source is request")
    end
    if waste? && waste_report.blank?
      errors.add(:waste_report, "is required when source is waste")
    end
  end
end
