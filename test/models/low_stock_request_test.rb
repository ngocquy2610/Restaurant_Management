require "test_helper"

class LowStockRequestTest < ActiveSupport::TestCase
  test "non-kitchen requester is rejected" do
    request = LowStockRequest.new(user: users(:customer), ingredient: ingredients(:two),
                                  note: "Need cheese")
    assert_not request.valid?
    assert_includes request.errors[:user], "must be kitchen staff"
  end

  test "inventory manager is also rejected as requester" do
    request = LowStockRequest.new(user: users(:one), ingredient: ingredients(:two))
    assert_not request.valid?
  end

  test "review! records reviewer, decision and timestamp" do
    request = low_stock_requests(:pending_request)

    assert_difference("Notification.count", 0) do
      request.review!(users(:one), "approved")
    end

    assert request.reload.approved?
    assert_equal users(:one).id, request.reviewed_by_id
    assert_not_nil request.reviewed_at
  end

  test "review! rejects an invalid decision" do
    request = low_stock_requests(:pending_request)
    assert_raises(ArgumentError) { request.review!(users(:one), "maybe") }
    assert request.reload.pending?
  end

  test "open scope covers pending and approved only" do
    assert_includes LowStockRequest.open, low_stock_requests(:pending_request)
    assert_includes LowStockRequest.open, low_stock_requests(:approved_request)

    low_stock_requests(:pending_request).update!(status: :rejected)
    assert_not_includes LowStockRequest.open, low_stock_requests(:pending_request)
  end
end
