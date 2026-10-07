require "test_helper"

class IngredientTest < ActiveSupport::TestCase
  test "status syncs from quantity on save" do
    ingredient = Ingredient.new(name: "Basil", unit: "kg", category: "produce",
                                unit_cost: 1, current_quantity: 10, low_stock_threshold: 3)
    ingredient.save!
    assert ingredient.in_stock?

    ingredient.update!(current_quantity: 2)
    assert ingredient.low_stock?

    ingredient.update!(current_quantity: 0)
    assert ingredient.out_of_stock?
  end

  test "low_stock enum scope returns only low stock rows" do
    assert_includes Ingredient.low_stock, ingredients(:two)
    assert_not_includes Ingredient.low_stock, ingredients(:one)
  end

  test "needs_restock includes out_of_stock but not healthy stock" do
    out = Ingredient.create!(name: "Salt", unit: "kg", category: "dry",
                             unit_cost: 1, current_quantity: 0, low_stock_threshold: 1)

    assert_includes Ingredient.needs_restock, out
    assert_includes Ingredient.needs_restock, ingredients(:two)
    assert_not_includes Ingredient.needs_restock, ingredients(:one)
  end

  test "category must be known" do
    ingredient = Ingredient.new(name: "Mystery", unit: "kg", category: "unicorn",
                                unit_cost: 1, current_quantity: 1, low_stock_threshold: 1)
    assert_not ingredient.valid?
    assert_includes ingredient.errors[:category], "is not included in the list"
  end

  test "negative quantity and negative threshold are rejected" do
    bad_qty = Ingredient.new(name: "Bad Qty", unit: "kg", category: "dry",
                             unit_cost: 1, current_quantity: -1, low_stock_threshold: 1)
    assert_not bad_qty.valid?

    bad_threshold = Ingredient.new(name: "Bad Threshold", unit: "kg", category: "dry",
                                   unit_cost: 1, current_quantity: 1, low_stock_threshold: -1)
    assert_not bad_threshold.valid?
  end

  test "cannot delete an ingredient that has transactions" do
    assert_not ingredients(:one).destroy
    assert ingredients(:one).errors[:base].any?
  end
end

