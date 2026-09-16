require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  setup do
    @order = orders(:one)
    @food = foods(:one)            # base_price 9.99
    @variant = food_variants(:one) # belongs to foods(:one), adjustment 9.99
  end

  test "unit price equals the base price when no variant is chosen" do
    item = OrderItem.new(order: @order, food: @food, quantity: 1)
    assert item.valid?
    assert_in_delta 9.99, item.unit_price, 0.001
  end

  test "unit price adds the variant adjustment when one is chosen" do
    item = OrderItem.new(order: @order, food: @food, food_variant: @variant, quantity: 1)
    assert item.valid?
    assert_in_delta 19.98, item.unit_price, 0.001
  end

  test "rejects a variant that does not belong to the food" do
    wrong = food_variants(:two) # belongs to foods(:two)
    item = OrderItem.new(order: @order, food: @food, food_variant: wrong, quantity: 1)
    assert_not item.valid?
    assert item.errors[:food_variant].any?
  end

  test "requires a positive quantity" do
    item = OrderItem.new(order: @order, food: @food, quantity: 0)
    assert_not item.valid?
    assert item.errors[:quantity].any?
  end

  test "recalculates the order total on save and destroy" do
    order = Order.create!(table: tables(:one))
    item = order.order_items.create!(food: @food, quantity: 2)
    order.reload
    assert_in_delta order.table_price.to_f + (9.99 * 2), order.total_price.to_f, 0.001

    item.destroy!
    order.reload
    assert_in_delta order.table_price.to_f, order.total_price.to_f, 0.001
  end
end
