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

  test "in_kitchen scope only returns kitchen-stage items ordered by creation time" do
    order = Order.create!(table: tables(:one))
    old = order.order_items.create!(food: @food, quantity: 1, status: :pending)
    accepted = order.order_items.create!(food: @food, quantity: 1, status: :accepted)
    ready = order.order_items.create!(food: @food, quantity: 1, status: :ready)

    queued = OrderItem.in_kitchen
    assert queued.include?(old)
    assert queued.include?(accepted)
    assert_not queued.include?(ready)
    assert queued.to_a.index(old) < queued.to_a.index(accepted)
  end

  test "accepting deducts stock and serving does not deduct again" do
    food, ingredient = build_dish(stock: 5, per_serving: 0.5)
    item = Order.create!(table: tables(:one)).order_items.create!(food: food, quantity: 2)

    item.update!(status: :accepted)
    assert_equal 4.to_d, ingredient.reload.current_quantity

    item.update!(status: :preparing)
    item.update!(status: :ready)
    item.update!(status: :served)
    assert_equal 4.to_d, ingredient.reload.current_quantity
  end

  test "accepting with short stock raises and keeps the item pending" do
    food, ingredient = build_dish(stock: 5, per_serving: 0.5)
    item = Order.create!(table: tables(:one)).order_items.create!(food: food, quantity: 2)
    ingredient.update!(current_quantity: 0.3)

    assert_raises(StockService::InsufficientStock) { item.update!(status: :accepted) }

    assert item.reload.pending?
    assert_equal 0.3.to_d, ingredient.reload.current_quantity
  end

  test "cancelling after accept restores stock once" do
    food, ingredient = build_dish(stock: 5, per_serving: 0.5)
    item = Order.create!(table: tables(:one)).order_items.create!(food: food, quantity: 2)
    item.update!(status: :accepted)

    item.update!(status: :cancelled)

    assert_equal 5.to_d, ingredient.reload.current_quantity
    assert_no_difference("StockTransaction.count") { StockService.restore_order_item!(item) }
  end

  test "cancelling a pending item leaves stock untouched" do
    food, ingredient = build_dish(stock: 5, per_serving: 0.5)
    item = Order.create!(table: tables(:one)).order_items.create!(food: food, quantity: 1)

    assert_no_difference("StockTransaction.count") { item.update!(status: :cancelled) }
    assert_equal 5.to_d, ingredient.reload.current_quantity
  end

  test "cannot create an item when ingredients are short" do
    food, _ = build_dish(stock: 0.2, per_serving: 0.5)
    item = OrderItem.new(order: Order.create!(table: tables(:one)), food: food, quantity: 1)

    assert_not item.valid?
    assert_match(/need 0.5/, item.errors.full_messages.to_sentence)
  end
end
