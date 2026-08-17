class FoodVariant < ApplicationRecord
  belongs_to :food

  has_many :recipe_items, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :food_id, case_sensitive: false }
  validates :price_adjustment, presence: true, numericality: true

  validate :final_price_not_negative

  def final_price
    food.base_price + price_adjustment
  end

  private

  def final_price_not_negative
    return unless food && price_adjustment

    if final_price.negative?
      errors.add(:price_adjustment, "can't bring the final price below 0")
    end
  end

end
