require "test_helper"

class OrderItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @waiter = users(:waiter)
    @order = orders(:one)
    @order_item = order_items(:one)
    sign_in @waiter
  end

  test "should add an item to an existing order" do
    assert_difference("OrderItem.count") do
      post order_items_url, params: {
        order_id: @order.id,
        order_item: { food_id: foods(:two).id, quantity: 1 }
      }
    end
    assert_redirected_to order_url(@order)
  end

  test "should update item status" do
    patch update_status_order_item_url(@order_item), params: { order_item: { status: "accepted" } }
    assert_redirected_to order_url(@order)
    assert @order_item.reload.accepted?
  end

  test "should destroy an order item" do
    assert_difference("OrderItem.count", -1) do
      delete order_item_url(@order_item)
    end
    assert_redirected_to order_url(@order)
  end
end
