require "test_helper"

class PromotionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @promotion = promotions(:one)
    sign_in users(:admin)
  end

  test "should get index" do
    get promotions_url
    assert_response :success
  end

  test "should get new" do
    get new_promotion_url
    assert_response :success
  end

  test "should create promotion" do
    assert_difference("Promotion.count") do
      post promotions_url, params: {
        promotion: {
          name: "Test Promotion",
          discount_type: "percentage",
          discount_value: 20,
          start_date: "2026-09-01T09:00",
          end_date: "2026-09-30T21:00",
          status: "published"
        }
      }
    end

    assert_redirected_to promotions_url
    assert_equal "Promotion added.", flash[:notice]
  end

  test "should show promotion" do
    get promotion_url(@promotion)
    assert_response :success
  end

  test "should get edit" do
    get edit_promotion_url(@promotion)
    assert_response :success
  end

  test "should update promotion" do
    patch promotion_url(@promotion), params: {
      promotion: {
        name: "Updated Promotion",
        discount_type: "fix_amount",
        discount_value: 5.50,
        start_date: "2026-09-01T09:00",
        end_date: "2026-09-30T21:00",
        status: "cancelled"
      }
    }

    assert_redirected_to promotions_url
    @promotion.reload
    assert_equal "Updated Promotion", @promotion.name
    assert_equal "fix_amount", @promotion.discount_type
    assert_equal "cancelled", @promotion.status
  end

  test "should rerender new with errors on invalid create" do
    assert_no_difference("Promotion.count") do
      post promotions_url, params: { promotion: { name: "" } }
    end

    assert_response :unprocessable_content
  end

  test "should destroy promotion" do
    assert_difference("Promotion.count", -1) do
      delete promotion_url(@promotion)
    end

    assert_redirected_to promotions_url
  end
end
