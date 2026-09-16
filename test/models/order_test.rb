require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @table = tables(:one)
  end

  test "valid order persists with a table" do
    order = Order.new(table: @table)
    assert order.valid?
  end

  test "requires a table" do
    order = Order.new(table: nil)
    assert_not order.valid?
    assert order.errors[:table].any?
  end

  test "defaults status to inserve" do
    order = Order.new(table: @table)
    assert order.inserve?
  end

  test "pulls table price from the table type on create" do
    order = Order.create!(table: @table)
    assert_equal @table.table_type.price_add_on.to_f, order.table_price.to_f
  end

  test "computes total from table price plus line items" do
    order = Order.create!(table: @table)
    order.order_items.create!(food: foods(:one), quantity: 2) # base 9.99 -> 19.98
    order.reload
    expected = @table.table_type.price_add_on.to_f + (9.99 * 2)
    assert_in_delta expected, order.total_price.to_f, 0.001
  end

  test "accepts nested order items on create" do
    order = Order.new(
      table: @table,
      order_items_attributes: [{ food_id: foods(:one).id, quantity: 1 }]
    )
    assert order.save
    assert_equal 1, order.order_items.size
  end

  test "records the waiter who takes the order" do
    order = Order.new(table: @table, waiter: users(:waiter))
    assert order.save
    assert_equal users(:waiter), order.waiter
  end

  test "inserve order marks the table occupied" do
    table = tables(:two)
    order = Order.create!(table: table, status: :inserve)
    assert order.inserve?
    assert table.reload.occupied?
  end

  test "completed order frees the table" do
    order = Order.create!(table: @table, status: :inserve)
    order.update!(status: :completed)
    assert @table.reload.available?
  end
end
