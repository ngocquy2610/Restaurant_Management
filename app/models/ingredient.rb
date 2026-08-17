class Ingredient < ApplicationRecord
  has_many :recipe_items, dependent: :restrict_with_error
  has_many :foods, through: :recipe_items

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :unit, presence: true, inclusion: { in: %w[kg g liter ml piece] }
  validates :unit_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :current_stock, numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, numericality: { greater_than_or_equal_to: 0 }
end