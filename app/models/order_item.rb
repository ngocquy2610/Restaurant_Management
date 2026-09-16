class OrderItem < ApplicationRecord
  belongs_to :order, touch: true
  belongs_to :food
  belongs_to :food_variant, optional: true

  enum :status, { pending: 0, accepted: 1, preparing: 2, ready: 3, served: 4, cancelled: 5 }

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :special_note, length: { maximum: 255 }, allow_nil: true

  validate :food_variant_belongs_to_food

  before_validation :assign_unit_price
  after_save :recalculate_order_total
  after_destroy :recalculate_order_total

  def assign_unit_price
    return if food.blank?

    price = food.base_price.to_f + (food_variant ? food_variant.price_adjustment.to_f : 0)
    self.unit_price = price.round(2)
  end

  private

  def food_variant_belongs_to_food
    return if food_variant.blank? || food.blank?

    if food_variant.food_id != food_id
      errors.add(:food_variant, "Wrong food variant")
    end
  end

  def recalculate_order_total
    order.recalculate_total_price!
  end
end
