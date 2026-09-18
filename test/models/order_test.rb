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

  test "completing a paid order marks its linked reservation completed" do
    reservation = Reservation.create!(
      user: users(:one),
      table: tables(:booked_a),
      guest_name: "Jane Smith",
      guest_phone: "5551234567",
      reservation_date: Date.current + 1,
      reservation_time: "19:00",
      status: :approved
    )
    order = Order.create!(table: reservation.table, reservation: reservation, status: :preorder)

    assert reservation.reload.approved?

    order.update!(status: :completed)
    assert reservation.reload.completed?
  end

  test "completing an order without a reservation raises no error" do
    order = Order.create!(table: @table, status: :inserve)
    order.update!(status: :completed)
    assert @table.reload.available?
  end

  test "applies the customer's membership discount to the total" do
    table = tables(:booked_a) # available in fixtures
    # users(:one) is silver (10% off).
    reservation = Reservation.create!(
      user: users(:one),
      table: table,
      guest_name: "Jane Smith",
      guest_phone: "5551234567",
      status: :approved
    )
    order = Order.create!(table: table, reservation: reservation, status: :preorder)
    order.order_items.create!(food: foods(:one), quantity: 1) # unit price 9.99

    subtotal = order.subtotal.to_f
    expected_discount = (subtotal * 0.10).round(2)

    assert_equal 10, order.membership_discount_percent
    assert_in_delta expected_discount, order.reload.discount_amount.to_f, 0.01
    assert_in_delta (subtotal - expected_discount), order.total_price.to_f, 0.01
  end

  test "applies no membership discount when no customer is linked" do
    order = Order.create!(table: tables(:booked_b))
    order.order_items.create!(food: foods(:one), quantity: 1)

    assert_equal 0, order.membership_discount_percent
    assert_equal 0.0, order.reload.discount_amount.to_f
  end
end
