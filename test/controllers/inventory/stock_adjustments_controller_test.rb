require "test_helper"

class Inventory::StockAdjustmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:admin) }

  test "new renders the adjustment form" do
    get new_inventory_stock_adjustment_url
    assert_response :success
  end

  test "new can preselect an ingredient" do
    get new_inventory_stock_adjustment_url(ingredient_id: ingredients(:one).id)
    assert_response :success
  end

  test "create posts an adjustment transaction" do
    ingredient = Ingredient.create!(name: "Adjust Me", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 5, low_stock_threshold: 1)

    assert_difference -> { ingredient.stock_transactions.adjustment.count }, 1 do
      post inventory_stock_adjustments_url,
           params: { stock_adjustment: { ingredient_id: ingredient.id, physical_count: 3, reason: "Count" } }
    end

    assert_redirected_to ingredient_url(ingredient)
    assert_equal 3.to_d, ingredient.reload.current_quantity
  end

  test "blank physical count is rejected" do
    post inventory_stock_adjustments_url,
         params: { stock_adjustment: { ingredient_id: ingredients(:one).id, physical_count: "" } }
    assert_response :unprocessable_content
  end

  test "negative physical count is rejected" do
    post inventory_stock_adjustments_url,
         params: { stock_adjustment: { ingredient_id: ingredients(:one).id, physical_count: -5 } }
    assert_response :unprocessable_content
  end

  test "no difference writes no transaction" do
    ingredient = ingredients(:one)

    assert_no_difference("StockTransaction.count") do
      post inventory_stock_adjustments_url,
           params: { stock_adjustment: { ingredient_id: ingredient.id, physical_count: ingredient.current_quantity } }
    end

    assert_redirected_to ingredient_url(ingredient)
  end
end
