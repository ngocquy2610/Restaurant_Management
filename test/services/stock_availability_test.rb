require "test_helper"

class StockAvailabilityTest < ActiveSupport::TestCase
  test "no shortage when stock covers the recipe" do
    food, _ = build_dish(stock: 5, per_serving: 0.5)
    assert_empty StockAvailability.shortages(food_id: food.id, quantity: 2)
  end

  test "reports a shortage with needed and available amounts" do
    food, ingredient = build_dish(stock: 0.4, per_serving: 0.5)

    shortage = StockAvailability.shortages(food_id: food.id, quantity: 1).first

    assert_equal ingredient, shortage.ingredient
    assert_equal 0.5.to_d, shortage.needed
    assert_equal 0.4.to_d, shortage.available
    assert_match(/need 0.5/, shortage.message)
  end

  test "an inactive ingredient counts as a shortage" do
    food, ingredient = build_dish(stock: 10)
    ingredient.deactivate!

    assert_equal 1, StockAvailability.shortages(food_id: food.id).size
  end

  test "variant recipe wins over the base recipe" do
    food, base_ingredient = build_dish(stock: 10, per_serving: 0.1)
    variant = FoodVariant.create!(food: food, name: "Large", price_adjustment: 2)
    scarce = Ingredient.create!(name: "Scarce #{SecureRandom.hex(3)}", unit: "kg", category: "other",
                                unit_cost: 1, current_quantity: 0, low_stock_threshold: 0)
    RecipeItem.create!(food: food, food_variant: variant, ingredient: scarce, quantity_required: 1)

    assert_empty StockAvailability.shortages(food_id: food.id)
    assert_equal [scarce], StockAvailability.shortages(food_id: food.id, variant_id: variant.id).map(&:ingredient)
    assert_not_equal base_ingredient, scarce
  end

  test "unavailable_food_ids lists dishes whose base recipe cannot be made" do
    short_food, = build_dish(stock: 0, per_serving: 1)
    ok_food, = build_dish(stock: 10, per_serving: 1)

    ids = StockAvailability.unavailable_food_ids

    assert_includes ids, short_food.id
    assert_not_includes ids, ok_food.id
  end
end
