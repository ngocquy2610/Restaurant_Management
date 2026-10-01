class OrderItem < ApplicationRecord
  belongs_to :order, touch: true
  belongs_to :food
  belongs_to :food_variant, optional: true

  enum :status, { pending: 0, accepted: 1, preparing: 2, ready: 3, served: 4, cancelled: 5 }, default: :pending

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :special_note, length: { maximum: 255 }, allow_nil: true

  validate :food_variant_belongs_to_food

  before_validation :assign_unit_price
  after_save :recalculate_order_total
  after_destroy :recalculate_order_total
  after_update :auto_consume_stock, if: -> { saved_change_to_status? && served? }

  IN_KITCHEN_STATUSES = %i[pending accepted preparing] #Array of Symbols

  scope :in_kitchen, -> {
    preorder = connection.quote(Order.statuses[:preorder]) # Change to sql value

    joins(:order)
      .where(status: IN_KITCHEN_STATUSES)
      .where("orders.status != ? OR orders.released_to_kitchen_at IS NOT NULL", Order.statuses[:preorder])
      .order(Arel.sql(<<~SQL.squish))
        CASE WHEN orders.status = #{preorder} AND orders.released_to_kitchen_at IS NOT NULL THEN 0 ELSE 1 END ASC,
        orders.released_to_kitchen_at ASC NULLS LAST,
        order_items.created_at ASC
      SQL

      # heredoc - allow to write in many lines
  }

  def assign_unit_price
    return if food.blank?

    price = food.base_price.to_f + (food_variant ? food_variant.price_adjustment.to_f : 0)
    self.unit_price = price.round(2)
  end

  def consumption_recipe_items
    if food_variant_id.present?
      variant_items = RecipeItem.includes(:ingredient)
                                .where(food_id: food_id, food_variant_id: food_variant_id)
      return variant_items.to_a if variant_items.any?
    end
    RecipeItem.includes(:ingredient).where(food_id: food_id, food_variant_id: nil).to_a
  end

  def auto_consume_stock
    StockService.consume_order_item!(self)
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
