require "test_helper"

# Verifies the reusable Kaminari pagination component in app/views/kaminari
# renders our branded Tailwind markup (instead of Kaminari's plain defaults)
# on the admin dashboard, which calls <code>paginate @reservations</code>.
class PaginationComponentTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "custom pagination partials render branded Tailwind markup on the dashboard" do
    # Two approved reservations with per(1) => 2 pages, so the pager renders.
    get admin_dashboards_url(page: 2)
    assert_response :success

    assert_select 'nav[aria-label="Pagination"]'
    assert_includes response.body, "rounded-full"
    assert_includes response.body, "bg-[#8A1C2B]" # active page = brand maroon
    assert_includes response.body, 'rel="prev"'
    assert_includes response.body, 'aria-label="Previous page"'
  end
end
