require "test_helper"

class StockTransactionTest < ActiveSupport::TestCase
  test "stock_in adds and snapshots before/after" do
    ingredient = ingredients(:one)
    ingredient.update!(current_quantity: 4)

    tx = StockTransaction.create!(ingredient: ingredient, transaction_type: :stock_in, quantity: 3)

    assert_equal 4.to_d, tx.quantity_before
    assert_equal 7.to_d, tx.quantity_after
  end

  test "stock_out signs the quantity negative" do
    tx = StockTransaction.new(transaction_type: :stock_out, quantity: 2)
    assert_equal(-2.to_d, tx.signed_quantity)
  end

  test "waste signs the quantity negative" do
    tx = StockTransaction.new(transaction_type: :waste, quantity: 1.5)
    assert_equal(-1.5.to_d, tx.signed_quantity)
  end

  test "quantity must be positive" do
    tx = StockTransaction.new(ingredient: ingredients(:one),
                              transaction_type: :stock_in, quantity: 0)
    assert_not tx.valid?
    assert_includes tx.errors[:quantity], "must be greater than 0"
  end

  test "fixture ledger rows are internally consistent" do
    tx = stock_transactions(:stock_in_one)
    assert_equal(tx.quantity_before + tx.quantity, tx.quantity_after)
  end
end
