require "test_helper"

class Inventory::LowStockRequestsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:admin) }

  test "index renders" do
    get inventory_low_stock_requests_url
    assert_response :success
  end

  test "index filters by status" do
    get inventory_low_stock_requests_url(status: "pending")
    assert_response :success
  end

  test "show renders current stock" do
    get inventory_low_stock_request_url(low_stock_requests(:pending_request))
    assert_response :success
  end

  test "approve creates a restock task and approves the request" do
    ingredient = Ingredient.create!(name: "Ctrl Approve", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 1, low_stock_threshold: 5)
    request = LowStockRequest.create!(user: users(:kitchen_staff), ingredient: ingredient, note: "low")

    assert_difference("RestockTask.count", 1) do
      patch review_inventory_low_stock_request_url(request),
            params: { low_stock_request: { status: "approved" } }
    end

    assert request.reload.approved?
    assert_redirected_to inventory_low_stock_request_url(request)
  end

  test "reject without a reason is refused" do
    request = low_stock_requests(:pending_request)

    patch review_inventory_low_stock_request_url(request),
          params: { low_stock_request: { status: "rejected" } }

    assert request.reload.pending?
    assert_redirected_to inventory_low_stock_request_url(request)
  end

  test "reject with a reason stores it" do
    request = low_stock_requests(:pending_request)

    patch review_inventory_low_stock_request_url(request),
          params: { low_stock_request: { status: "rejected", review_note: "Enough stock" } }

    assert request.reload.rejected?
    assert_equal "Enough stock", request.review_note
  end
end
