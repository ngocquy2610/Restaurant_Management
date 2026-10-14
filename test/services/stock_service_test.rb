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

class RestaurantPerformanceServiceTest < ActiveSupport::TestCase
  test "call includes monthly revenue trend data" do
    payment_method = PaymentMethod.find_or_create_by!(code: :cash) do |method|
      method.name = "Cash"
    end
    table = tables(:one)

    order_1 = Order.create!(table: table, status: :completed)
    order_2 = Order.create!(table: table, status: :completed)

    Payment.create!(order: order_1, payment_method: payment_method, subtotal: 100, discount_amount: 0,
                    total_amount: 100, currency: "USD", status: :completed,
                    paid_at: 2.months.ago.beginning_of_month + 5.days)
    Payment.create!(order: order_2, payment_method: payment_method, subtotal: 250, discount_amount: 0,
                    total_amount: 250, currency: "USD", status: :completed,
                    paid_at: 1.month.ago.beginning_of_month + 7.days)

    service = RestaurantPerformanceService.new(
      from_date: 3.months.ago.to_date,
      to_date: Date.current,
      time_range: 3.months.ago.beginning_of_day..Date.current.end_of_day
    )

    performance = service.call

    assert_operator performance[:monthly_trend].size, :>=, 2
    assert_operator performance[:monthly_trend].values.sum.to_d, :>, 0
    assert_operator performance[:monthly_trend].keys.count { |month| month >= 3.months.ago.to_date.beginning_of_month }, :>=, 1
  end
end
