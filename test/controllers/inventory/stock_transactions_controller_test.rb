require "test_helper"

class Inventory::StockTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:admin) }

  test "index renders" do
    get inventory_stock_transactions_url
    assert_response :success
  end

  test "filters by transaction type" do
    get inventory_stock_transactions_url(transaction_type: "stock_in")
    assert_response :success
    assert_includes response.body, "Stock in"
    assert_not_includes response.body, "Stock out"
  end

  test "filters by ingredient" do
    get inventory_stock_transactions_url(ingredient_id: ingredients(:one).id)
    assert_response :success
  end

  test "invalid date range is ignored without error" do
    get inventory_stock_transactions_url(from: "not-a-date", to: "also-bad")
    assert_response :success
  end
end
