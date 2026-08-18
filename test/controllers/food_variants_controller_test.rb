require "test_helper"

class FoodVariantsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(
      full_name: "Admin User",
      email: "fv-admin@example.com",
      phone: "5551234567",
      password: "password",
      role: :admin
    )
    sign_in @admin

    @food_variant = food_variants(:one)
  end

  test "should get index" do
    get food_variants_url
    assert_response :success
  end

  test "should get new food variant page with the creation form" do
    get new_food_variant_url
    assert_response :success

    assert_select "form" do
      assert_select "input[name='food_variant[name]']"
      assert_select "select[name='food_variant[food_id]']"
      assert_select "input[name='food_variant[price_adjustment]']"
      assert_select "input[type='submit'][value='Create Food variant']"
    end
  end

  test "should create food_variant" do
    assert_difference("FoodVariant.count") do
      post food_variants_url, params: {
        food_variant: { food_id: foods(:one).id, name: "Large", price_adjustment: 2.50 }
      }
    end

    assert_redirected_to food_variants_url
  end

  test "invalid create re-renders the creation form" do
    assert_no_difference("FoodVariant.count") do
      post food_variants_url, params: {
        food_variant: { food_id: foods(:one).id, name: "", price_adjustment: 2.50 }
      }
    end

    assert_response :unprocessable_content
    assert_select "form" do
      assert_select "input[name='food_variant[name]']"
      assert_select "select[name='food_variant[food_id]']"
    end
    assert_select "#error_explanation"
  end

  test "should show food_variant" do
    get food_variant_url(@food_variant)
    assert_response :success
  end

  test "should get edit food variant page with the update form" do
    get edit_food_variant_url(@food_variant)
    assert_response :success

    assert_select "form" do
      assert_select "input[name='food_variant[name]'][value='#{@food_variant.name}']"
      assert_select "select[name='food_variant[food_id]']"
      assert_select "input[name='food_variant[price_adjustment]']"
      assert_select "input[type='submit'][value='Update Food variant']"
    end
  end

  test "should update food_variant" do
    patch food_variant_url(@food_variant), params: {
      food_variant: { food_id: foods(:one).id, name: "Family", price_adjustment: 5.00 }
    }

    assert_redirected_to food_variant_url(@food_variant)
    @food_variant.reload
    assert_equal "Family", @food_variant.name
    assert_equal 5.00, @food_variant.price_adjustment.to_f
  end

  test "invalid update re-renders the update form" do
    patch food_variant_url(@food_variant), params: {
      food_variant: { name: "" }
    }

    assert_response :unprocessable_content
    assert_select "form" do
      assert_select "input[name='food_variant[name]']"
      assert_select "select[name='food_variant[food_id]']"
    end
    assert_select "#error_explanation"
  end

  test "should destroy food_variant" do
    assert_difference("FoodVariant.count", -1) do
      delete food_variant_url(@food_variant)
    end

    assert_redirected_to food_variants_url
  end
end

