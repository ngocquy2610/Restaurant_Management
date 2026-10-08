class Review < ApplicationRecord
  belongs_to :reservation
  belongs_to :customer, class_name: "User", foreign_key: :user_id, optional: true

  has_one_attached :image

  before_validation :assign_customer, on: :create

  validates :rating, presence: true,
                     numericality: { only_integer: true, in: 1..5 }
  validates :comment, length: { maximum: 1000 }, allow_blank: true
  validate  :customer_must_match_reservation
  validate  :reservation_must_be_reviewable, on: :create
  validate  :one_review_per_customer

  scope :recent,  -> { order(created_at: :desc) }
  # `customer` powers `reviewer_name` on every card, so it must be preloaded too.
  scope :visible, -> { includes(:customer, reservation: [:table, :user]) }

  def self.for_customer(customer) = where(user_id: customer.id)

  def self.average_rating(scope = nil) = (scope || all).average(:rating)&.round(1)

  def reviewer = customer || reservation&.user

  def reviewer_name
    reviewer&.full_name.presence || reservation&.guest_name.presence || "Guest"
  end

  def table = reservation&.table

  def meal_at = reservation&.slot_start

  def meal_label
    at = meal_at
    at ? "#{at.strftime('%d %b %Y')} · #{at.strftime('%I:%M %p')}" : "—"
  end

  private

  def assign_customer
    self.user_id ||= reservation&.user_id
  end

  def customer_must_match_reservation
    return if reservation.blank? || user_id.blank?
    errors.add(:user_id, "must match the reservation's customer") if user_id != reservation.user_id
  end

  def reservation_must_be_reviewable
    return if reservation.blank?
    errors.add(:reservation, "cannot be reviewed yet") unless reservation.reviewable?
  end

  # Every customer gets exactly one restaurant review, ever.
  def one_review_per_customer
    return if user_id.blank?
    return unless self.class.where(user_id: user_id).where.not(id: id).exists?

    errors.add(:base, "You have already reviewed the restaurant.")
  end
end
