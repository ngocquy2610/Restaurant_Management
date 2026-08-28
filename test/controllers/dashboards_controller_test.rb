require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "should get index and show promotions link" do
    get admin_dashboards_url
    assert_response :success

    assert_select "h1", /Restaurant Overview/
    assert_select "a[href='/promotions']", text: /Promotions/i
  end

  test "recent reservations shows active reservations from the database" do
    get admin_dashboards_url
    assert_response :success

    # Both fixtures are approved (active), so they show in the table.
    assert_select "h2", /Recent Reservations/
    assert_select "td", text: /#{reservations(:one).guest_name}/
    assert_select "a[href='/admin/reservations']", text: /View all/i
  end
end