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
end