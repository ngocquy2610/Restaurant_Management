require "test_helper"

class PreordersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = users(:customer)
    # A booking owned by the customer (available table so it can be booked).
    @reservation = Reservation.create!(
      user: @customer,
      table: tables(:booked_a),
      guest_name: "Customer User",
      guest_phone: "5551112222"
    )
    sign_in @customer
  end

  test "customer sees the preorder screen after booking" do
    get new_reservation_preorder_path(@reservation)
    assert_response :success
    assert_match "Choose your dishes", response.body
  end

  test "customer can create a preorder directly on the orders table" do
    assert_difference("Order.count") do
      post reservation_preorders_path(@reservation), params: {
        order: {
          reservation_id: @reservation.id,
          order_items_attributes: {
            "0" => { food_id: foods(:one).id, quantity: 2 }
          }
        }
      }
    end

    order = Order.last
    assert_equal @reservation, order.reservation
    assert_equal @customer, order.waiter
    assert order.preorder?, "a customer pre-order should be a preorder order"
    assert_equal @reservation.table, order.table
    assert_equal 1, order.order_items.size
    assert_in_delta 9.99, order.order_items.first.unit_price, 0.001
    assert_redirected_to preorder_path(order)
  end

  test "customer can view their preorder confirmation" do
    order = create_customer_preorder
    get preorder_path(order)
    assert_response :success
    assert_match "Pre-order confirmed", response.body
  end

  test "staff can list preorders" do
    sign_out @customer
    sign_in users(:admin)

    get preorders_path
    assert_response :success
  end

  private

  def create_customer_preorder
    post reservation_preorders_path(@reservation), params: {
      order: {
        reservation_id: @reservation.id,
        order_items_attributes: {
          "0" => { food_id: foods(:one).id, quantity: 1 }
        }
      }
    }
    Order.last
  end
end
