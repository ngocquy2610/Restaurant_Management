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

  test "recent scope orders newest first" do
    ids = WasteReport.recent.ids
    assert_equal ids.sort.reverse, ids
  end
end
