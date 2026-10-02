require "test_helper"

class IngredientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ingredient = ingredients(:one)
    sign_in users(:admin)
  end

  test "should get index" do
    get ingredients_url
    assert_response :success
  end

  test "index filters by status" do
    get ingredients_url(status: "low_stock")
    assert_response :success
    assert_includes response.body, ingredients(:two).name
    assert_not_includes response.body, ingredients(:one).name
  end

  test "index searches by name" do
    get ingredients_url(q: "Tom")
    assert_response :success
    assert_includes response.body, ingredients(:one).name
    assert_not_includes response.body, ingredients(:two).name
  end

  test "should get new" do
    get new_ingredient_url
    assert_response :success
  end

  test "should create ingredient" do
    assert_difference("Ingredient.count") do
      post ingredients_url, params: { ingredient: {
        name: "Saffron", unit: "g", category: "dry",
        unit_cost: 5, current_quantity: 10, low_stock_threshold: 2
      } }
    end

    assert_redirected_to ingredients_url
  end

  test "should show ingredient" do
    get ingredient_url(@ingredient)
    assert_response :success
  end

  test "should get edit" do
    get edit_ingredient_url(@ingredient)
    assert_response :success
  end

  test "should update ingredient" do
    patch ingredient_url(@ingredient), params: { ingredient: { unit_cost: 12 } }
    assert_redirected_to ingredients_url
  end

  test "should deactivate ingredient" do
    patch deactivate_ingredient_url(@ingredient)
    assert_redirected_to ingredients_url
    assert_not @ingredient.reload.active?
  end

  test "should reactivate ingredient" do
    @ingredient.deactivate!
    patch reactivate_ingredient_url(@ingredient)
    assert @ingredient.reload.active?
  end

  test "should destroy ingredient" do
    ingredient = Ingredient.create!(name: "Disposable", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 1, low_stock_threshold: 0)

    assert_difference("Ingredient.count", -1) do
      delete ingredient_url(ingredient)
    end

    assert_redirected_to ingredients_url
  end
end
