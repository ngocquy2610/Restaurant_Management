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
end