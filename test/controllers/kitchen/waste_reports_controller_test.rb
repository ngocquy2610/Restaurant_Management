require "test_helper"

class Kitchen::WasteReportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:kitchen_staff) }

  test "index renders own reports" do
    get kitchen_waste_reports_url
    assert_response :success
  end

  test "new renders the form" do
    get new_kitchen_waste_report_url
    assert_response :success
  end

  test "show renders own report" do
    get kitchen_waste_report_url(waste_reports(:pending_waste))
    assert_response :success
  end

  test "create stores a pending report owned by the current user" do
    assert_difference("WasteReport.count", 1) do
      post kitchen_waste_reports_url,
           params: { waste_report: { ingredient_id: ingredients(:one).id,
                                     quantity: 2, reason: "Dropped tray" } }
    end

    report = WasteReport.order(:id).last
    assert report.pending?
    assert_equal users(:kitchen_staff).id, report.user_id
    assert_equal ingredients(:one).id, report.ingredient_id
    assert_redirected_to kitchen_waste_reports_url
  end

  test "create rejects a blank reason" do
    assert_no_difference("WasteReport.count") do
      post kitchen_waste_reports_url,
           params: { waste_report: { ingredient_id: ingredients(:one).id,
                                     quantity: 2, reason: "" } }
    end

    assert_response :unprocessable_content
  end
end
