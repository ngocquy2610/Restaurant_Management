class LowStockRequest < ApplicationRecord
  belongs_to :user                                    # người gửi (kitchen staff)
  belongs_to :ingredient
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, completed: 3 }, default: :pending

  scope :recent, -> { order(created_at: :desc) }
  scope :open,   -> { where(status: %i[pending approved]) }

  validates :note, length: { maximum: 500 }, allow_blank: true
  validate  :requester_must_be_kitchen_staff

  def review!(reviewer, decision)
    decision = decision.to_s
    unless %w[approved rejected completed].include?(decision)
      raise ArgumentError, "invalid decision: #{decision}"
    end

    update!(status: decision, reviewed_by: reviewer, reviewed_at: Time.zone.now)
  end

  private

  def requester_must_be_kitchen_staff
    return if user.blank?
    return if user.kitchen_staff? || user.admin?

    errors.add(:user, "must be kitchen staff")
  end
end
