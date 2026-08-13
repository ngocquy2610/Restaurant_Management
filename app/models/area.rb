class Area < ApplicationRecord
  has_one_attached :image

  validate :image_format

  has_many :tables, dependent: :nullify, dependent: :destroy
  
  validates :name, presence: true

  enum :area_type, {
    indoor: 0,
    outdoor: 1
  }, presence: true

  validates :floor_level, presence: true

  private

  def image_format
    return unless image.attached?

    unless image.content_type.in?(%w[image/png image/jpeg image/jpg image/webp])
      errors.add(:image, "must be a PNG, JPEG, or WEBP")
    end
  end
end
