class RecipeItem < ApplicationRecord
  belongs_to :food
  belongs_to :food_variant, optional: true
  belongs_to :ingredient

  validates :quantity_required, presence: true, numericality: { greater_than: 0 }
  validates :ingredient_id, uniqueness: { scope: [:food_id, :food_variant_id] }

  validate :variant_belongs_to_food

  private

  def variant_belongs_to_food
    return unless food_variant

    if food_variant.food_id != food_id
      errors.add(:food_variant, "must belong to the same food")
    end
  end
end
