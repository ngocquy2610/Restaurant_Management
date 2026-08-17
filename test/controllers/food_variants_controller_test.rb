require "test_helper"

class FoodVariantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @food_variant = food_variants(:one)
  end

  test "should get index" do
    get food_variants_url
    assert_response :success
  end

  test "should get new" do
    get new_food_variant_url
    assert_response :success
  end

  test "should create food_variant" do
    assert_difference("FoodVariant.count") do
      post food_variants_url, params: { food_variant: {} }
    end

    assert_redirected_to food_variant_url(FoodVariant.last)
  end

  test "should show food_variant" do
    get food_variant_url(@food_variant)
    assert_response :success
  end

  test "should get edit" do
    get edit_food_variant_url(@food_variant)
    assert_response :success
  end

  test "should update food_variant" do
    patch food_variant_url(@food_variant), params: { food_variant: {} }
    assert_redirected_to food_variant_url(@food_variant)
  end

  test "should destroy food_variant" do
    assert_difference("FoodVariant.count", -1) do
      delete food_variant_url(@food_variant)
    end

    assert_redirected_to food_variants_url
  end
end
