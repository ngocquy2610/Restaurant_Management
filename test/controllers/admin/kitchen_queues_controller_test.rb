require "test_helper"
require "turbo/broadcastable/test_helper"

class Admin::KitchenQueuesControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    @kitchen = users(:kitchen_staff)
    @order = orders(:one)
    @order_item = order_items(:one) # status: accepted (in_kitchen)
    @waiter = users(:waiter)
  end

  test "kitchen staff can view the queue" do
    sign_in @kitchen
    get admin_kitchen_queues_url
    assert_response :success
  end

  test "admin can view the queue" do
    sign_in users(:admin)
    get admin_kitchen_queues_url
    assert_response :success
  end

  test "customer is forbidden from the queue" do
    sign_in users(:customer)
    get admin_kitchen_queues_url
    assert_response :forbidden
  end

  test "kitchen staff can view an order detail with recipes" do
    sign_in @kitchen
    get admin_kitchen_queue_url(@order)
    assert_response :success
  end

  test "kitchen staff can advance an item to the next valid status" do
    sign_in @kitchen
    patch admin_kitchen_queue_update_item_status_url(@order, @order_item), params: {
      order_item: { status: "preparing" }
    }
    assert_redirected_to admin_kitchen_queue_url(@order)
    assert @order_item.reload.preparing?
  end

  test "cannot jump to an invalid status" do
    sign_in @kitchen
    patch admin_kitchen_queue_update_item_status_url(@order, @order_item), params: {
      order_item: { status: "served" }
    }
    assert_redirected_to admin_kitchen_queue_url(@order)
    assert @order_item.reload.accepted?
  end

  test "notifies waiters when an item becomes ready" do
    preparing = OrderItem.create!(
      order: @order, food: foods(:one), quantity: 1, unit_price: 9.99, status: :preparing
    )

    sign_in @kitchen
    assert_difference("Notification.where(recipient: @waiter).count", 1) do
      patch admin_kitchen_queue_update_item_status_url(@order, preparing), params: {
        order_item: { status: "ready" }
      }
    end
    assert preparing.reload.ready?
  end

  test "kitchen staff cannot be flagged as an order taker on create policy" do
    assert_not OrderItemPolicy.new(@kitchen, OrderItem.new).create?
  end
end