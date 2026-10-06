require "test_helper"

class Inventory::WasteReportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:admin) }

  test "index renders" do
    get inventory_waste_reports_url
    assert_response :success
  end

  test "index filters by status" do
    get inventory_waste_reports_url(status: "pending")
    assert_response :success
  end

  test "show renders" do
    get inventory_waste_report_url(waste_reports(:pending_waste))
    assert_response :success
  end

  test "approve creates a WASTE transaction and reduces stock" do
    ingredient = Ingredient.create!(name: "Ctrl Waste Approve", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 10, low_stock_threshold: 5)
    report = WasteReport.create!(user: users(:kitchen_staff), ingredient: ingredient,
                                 quantity: 2, reason: "spoiled")

    assert_difference -> { ingredient.stock_transactions.waste.count }, 1 do
      patch verify_inventory_waste_report_url(report),
            params: { waste_report: { status: "approved", verified_quantity: 2 } }
    end

    assert report.reload.approved?
    assert_equal 2.to_d, report.verified_quantity
    assert_equal 8.to_d, ingredient.reload.current_quantity
    assert_redirected_to inventory_waste_report_url(report)
  end

  test "approve with the restock checkbox opens a waste-sourced restock task" do
    ingredient = Ingredient.create!(name: "Ctrl Waste Restock", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 10, low_stock_threshold: 5)
    report = WasteReport.create!(user: users(:kitchen_staff), ingredient: ingredient,
                                 quantity: 2, reason: "spoiled")

    assert_difference("RestockTask.count", 1) do
      patch verify_inventory_waste_report_url(report),
            params: { waste_report: { status: "approved", verified_quantity: 2,
                                      create_restock_task: "1" } }
    end

    task = RestockTask.order(:id).last
    assert task.waste?
    assert_equal report, task.waste_report
    assert_equal ingredient, task.ingredient
    assert_redirected_to inventory_waste_report_url(report)
  end

  test "reject without a reason is refused" do
    report = waste_reports(:pending_waste)

    patch verify_inventory_waste_report_url(report),
          params: { waste_report: { status: "rejected" } }

    assert report.reload.pending?
    assert_redirected_to inventory_waste_report_url(report)
  end

  test "reject with a reason stores it" do
    report = waste_reports(:pending_waste)

    patch verify_inventory_waste_report_url(report),
          params: { waste_report: { status: "rejected", review_note: "Counted more" } }

    assert report.reload.rejected?
    assert_equal "Counted more", report.review_note
    assert_nil report.verified_quantity
    assert_redirected_to inventory_waste_report_url(report)
  end
end
