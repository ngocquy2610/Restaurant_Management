require "test_helper"

class StockServiceTest < ActiveSupport::TestCase
  test "restock creates a stock_in transaction and raises quantity" do
    ingredient = Ingredient.create!(name: "Service Restock", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 5, low_stock_threshold: 1)

    assert_difference -> { ingredient.stock_transactions.stock_in.count }, 1 do
      StockService.restock(ingredient: ingredient, quantity: 3)
    end

    assert_equal 8.to_d, ingredient.reload.current_quantity
  end

  test "adjust returns nil when there is no difference" do
    ingredient = ingredients(:one)
    assert_nil StockService.adjust(ingredient: ingredient, new_quantity: ingredient.current_quantity)
  end

  test "adjust writes an adjustment transaction with the signed delta" do
    ingredient = Ingredient.create!(name: "Service Adjust", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 10, low_stock_threshold: 1)

    tx = StockService.adjust(ingredient: ingredient, new_quantity: 7, reason: "Count")

    assert_equal "adjustment", tx.transaction_type
    assert_equal(-3.to_d, tx.quantity)
    assert_equal 7.to_d, ingredient.reload.current_quantity
  end

  test "auto-creates a restock task when stock drops to the threshold" do
    ingredient = Ingredient.create!(name: "Service Auto", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 10, low_stock_threshold: 5)

    assert_difference("RestockTask.count", 1) do
      StockService.apply_transaction(ingredient: ingredient, transaction_type: :stock_out, quantity: 6)
    end

    task = RestockTask.order(:id).last
    assert_equal ingredient.id, task.ingredient_id
    assert task.pending?
    assert task.auto?
    assert_equal 1.to_d, task.quantity # threshold 5 - current 4
  end

  test "does not duplicate an open restock task" do
    ingredient = Ingredient.create!(name: "Service NoDup", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 10, low_stock_threshold: 5)

    StockService.apply_transaction(ingredient: ingredient, transaction_type: :stock_out, quantity: 6)

    assert_no_difference("RestockTask.count") do
      StockService.apply_transaction(ingredient: ingredient, transaction_type: :stock_out, quantity: 1)
    end
  end
end
