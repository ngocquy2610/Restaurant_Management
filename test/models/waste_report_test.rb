require "test_helper"

class WasteReportTest < ActiveSupport::TestCase
  test "reason is required" do
    report = WasteReport.new(ingredient: ingredients(:one), user: users(:kitchen_staff),
                             quantity: 1, reason: nil)
    assert_not report.valid?
    assert report.errors[:reason].any?
  end

  test "verified quantity cannot exceed reported quantity" do
    report = WasteReport.new(ingredient: ingredients(:one), quantity: 1,
                             verified_quantity: 2, reason: "miscount")
    assert_not report.valid?
    assert_includes report.errors[:verified_quantity], "cannot exceed reported quantity"
  end

  test "review! defaults verified quantity to reported quantity" do
    report = waste_reports(:pending_waste)
    report.review!(users(:one), "approved")

    assert report.reload.approved?
    assert_equal report.quantity, report.verified_quantity
    assert_equal users(:one).id, report.reviewed_by_id
    assert_not_nil report.reviewed_at
  end

  test "review! accepts an explicit verified quantity" do
    report = waste_reports(:pending_waste)
    report.review!(users(:one), "approved", verified_quantity: 1.0)

    assert_equal 1.0.to_d, report.reload.verified_quantity
  end

  test "approve creates a WASTE transaction and reduces stock" do
    ingredient = Ingredient.create!(name: "Waste Model Approve", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 10, low_stock_threshold: 5)
    report = WasteReport.create!(ingredient: ingredient, user: users(:kitchen_staff),
                                 quantity: 2, reason: "spoiled")

    assert_difference -> { ingredient.stock_transactions.waste.count }, 1 do
      report.review!(users(:one), "approved", verified_quantity: 1.5)
    end

    assert report.reload.approved?
    assert_equal 1.5.to_d, report.verified_quantity
    assert_equal 8.5.to_d, ingredient.reload.current_quantity
  end

  test "approve can open a waste-sourced restock task" do
    ingredient = Ingredient.create!(name: "Waste Model Restock", unit: "kg", category: "other",
                                    unit_cost: 1, current_quantity: 10, low_stock_threshold: 5)
    report = WasteReport.create!(ingredient: ingredient, user: users(:kitchen_staff),
                                 quantity: 2, reason: "spoiled")

    assert_difference("RestockTask.count", 1) do
      report.review!(users(:one), "approved", create_restock_task: true)
    end

    task = RestockTask.order(:id).last
    assert task.waste?
    assert_equal report, task.waste_report
    assert_equal ingredient, task.ingredient
    assert task.quantity.positive?
  end

  test "reject requires a reason" do
    report = waste_reports(:pending_waste)
    assert_raises(ArgumentError) { report.review!(users(:one), "rejected") }
    assert report.reload.pending?
  end

  test "reject stores the reason, clears verified qty and leaves stock untouched" do
    ingredient = ingredients(:one)
    report = WasteReport.create!(ingredient: ingredient, user: users(:kitchen_staff),
                                 quantity: 1, reason: "spoiled")
    before = ingredient.current_quantity

    assert_no_difference -> { ingredient.stock_transactions.waste.count } do
      report.review!(users(:one), "rejected", note: "Counted more")
    end

    assert report.reload.rejected?
    assert_equal "Counted more", report.review_note
    assert_nil report.verified_quantity
    assert_equal before, ingredient.reload.current_quantity
  end

  test "review! refuses a second decision on the same report" do
    report = waste_reports(:pending_waste)
    report.review!(users(:one), "approved")

    assert_raises(ArgumentError) { report.review!(users(:one), "rejected", note: "nope") }
  end

  test "by_status filters valid statuses and ignores unknown ones" do
    assert_includes WasteReport.by_status("pending"), waste_reports(:pending_waste)
    assert_not_includes WasteReport.by_status("pending"), waste_reports(:approved_waste)
    assert_equal WasteReport.count, WasteReport.by_status("nonsense").count
  end

  test "recent scope orders newest first" do
    ids = WasteReport.recent.ids
    assert_equal ids.sort.reverse, ids
  end
end
