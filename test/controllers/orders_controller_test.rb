require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @waiter = users(:waiter)
    @order = orders(:one)
    sign_in @waiter
  end

  test "waiter can list orders" do
    get orders_url
    assert_response :success
  end

  test "waiter can open the new order form" do
    get new_order_url
    assert_response :success
  end

  test "new order form lists a table with a checked-in reservation" do
    table = tables(:booked_a)
    Reservation.create!(
      user: users(:one), table: table,
      guest_name: "Checked In", guest_phone: "0812345678",
      reservation_date: Date.current + 1, reservation_time: "19:00",
      status: :checked_in
    )
    assert table.reload.occupied?

    get new_order_url
    assert_response :success
    assert_select "input[name='order[table_id]'][value='#{table.id}']"
  end

  test "should create order with nested items for a customer" do
    assert_difference("Order.count") do
      post orders_url, params: {
        order: {
          table_id: tables(:two).id,
          order_items_attributes: {
            "0" => { food_id: foods(:one).id, quantity: 2 }
          }
        }
      }
    end

    order = Order.last
    assert_equal @waiter, order.waiter
    assert order.inserve?, "a waiter-placed order should be in service"
    assert_equal 1, order.order_items.size
    # per-unit base price for foods(:one); 2 units => 19.98 line total
    assert_in_delta 9.99, order.order_items.first.unit_price, 0.001
    notification = Notification.find_by!(recipient: users(:kitchen_staff), title: "New order at #{order.table.table_number}")
    assert_equal admin_kitchen_queue_path(order), notification.redirect_url
    assert_redirected_to order_url(order)
  end

  test "admin-placed order is marked in service" do
    sign_out @waiter
    sign_in users(:admin)

    assert_difference("Order.count") do
      post orders_url, params: { order: { table_id: tables(:two).id } }
    end

    order = Order.last
    assert_equal users(:admin), order.waiter
    assert order.inserve?, "an admin-placed order should be in service"
    assert_redirected_to order_url(order)
  end

  test "customer-placed order is marked as a preorder" do
    sign_out @waiter
    sign_in users(:customer)

    assert_difference("Order.count") do
      post orders_url, params: {
        order: {
          table_id: tables(:two).id,
          order_items_attributes: {
            "0" => { food_id: foods(:one).id, quantity: 1 }
          }
        }
      }
    end

    order = Order.last
    assert_equal users(:customer), order.waiter
    assert order.preorder?, "a customer-placed order should be a preorder"
    assert_redirected_to order_url(order)
  end

  test "should show order" do
    get order_url(@order)
    assert_response :success
    assert_select "a[href='/admin/dashboards']", text: /Back to dashboard/i
    assert_select "input[type='submit'][value='Create payment']", count: 1
  end

  test "should update order status" do
    patch update_status_order_url(@order), params: { order: { status: "completed" } }
    assert_redirected_to order_url(@order)
    assert @order.reload.completed?
  end

  test "admin sees the dashboard button on the orders page" do
    sign_out @waiter
    sign_in users(:admin)

    get orders_url
    assert_response :success
    assert_match "/admin/dashboards", response.body
    assert_match "New order", response.body
  end

  test "non-waiter staff cannot create an order" do
    sign_out @waiter
    sign_in users(:receptionist)

    assert_no_difference("Order.count") do
      post orders_url, params: { order: { table_id: tables(:one).id } }
    end
  end
end
