require "test_helper"

class Inventory::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:admin) }

  test "index renders with independent pagination parameters" do
    get inventory_reports_url(
      ingredients_page: 1,
      transactions_page: 1,
      restock_tasks_page: 1
    )

    assert_response :success
  end

  test "build_report_summary aggregates stock health and totals" do
    controller = Inventory::ReportsController.new
    controller.instance_variable_set(:@ingredients, Ingredient.active)

    summary = controller.send(:build_report_summary)

    assert_equal 2, summary[:total_ingredients]
    assert_operator summary[:total_stock_value].to_d, :>, 0
    assert_equal 1, summary[:low_stock_count]
    assert_equal 0, summary[:out_of_stock_count]
  end
end