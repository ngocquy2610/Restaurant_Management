class Food < ApplicationRecord
  belongs_to :category

  has_many :food_variants, dependent: :destroy
  has_many :recipe_items, dependent: :destroy
  has_many :ingredients, through: :recipe_items

  has_one_attached :image

  validates :name, presence: true, uniqueness: { scope: :category_id, case_sensitive: false }
  validates :base_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :description, length: { maximum: 2000 }, allow_blank: true

  enum :status, {
    active: 0,
    inactive: 1
  }

  validate :image_type_and_size

  private

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
