class WasteReport < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  scope :recent, -> { order(created_at: :desc) }

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :verified_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :reason, presence: true, length: { maximum: 500 }

  validate :verified_quantity_not_over_reported

  def review!(reviewer, decision, verified_quantity: nil)
    update!(status: decision, reviewed_by: reviewer,
            verified_quantity: verified_quantity || self.quantity,
            reviewed_at: Time.zone.now)
  end

  private

  def verified_quantity_not_over_reported
    return if verified_quantity.blank? || quantity.blank?
    return if verified_quantity.to_d <= quantity.to_d

    errors.add(:verified_quantity, "cannot exceed reported quantity")
  end
end
