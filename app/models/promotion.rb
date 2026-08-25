class Promotion < ApplicationRecord
  has_one_attached :image

  validates :name, presence: true
  enum :discount_type, {percentage: true, fix_amount: false}, default: true
  validates :discount_value, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :start_date, :end_date, presence: true

  validate :dates_valid
  validate :image_type_and_size

  enum :status, {
    published: 0,
    cancelled: 1
  }, default: 0

  private

  def dates_valid
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be after the start date") if end_date <= start_date
  end

  def image_type_and_size
    return unless image.attached?

    unless image.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:image, "must be a PNG, JPEG, or WEBP")
    end

    if image.byte_size > 5.megabytes
      errors.add(:image, "must be under 5MB")
    end
  end
end
