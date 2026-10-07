require "test_helper"

class Kitchen::LowStockRequestsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:kitchen_staff) }

  test "index renders own requests" do
    get kitchen_low_stock_requests_url
    assert_response :success
  end

  test "new renders the form" do
    get new_kitchen_low_stock_request_url
    assert_response :success
  end

  test "create stores urgency" do
    assert_difference("LowStockRequest.count", 1) do
      post kitchen_low_stock_requests_url,
           params: { low_stock_request: { ingredient_id: ingredients(:one).id,
                                          note: "Low", urgency: "high" } }
    end

    assert LowStockRequest.last.high?
    assert_redirected_to kitchen_low_stock_requests_url
  end
end
