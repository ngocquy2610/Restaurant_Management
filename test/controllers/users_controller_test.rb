require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(
      full_name: "Admin User",
      email: "users-admin@example.com",
      phone: "5556789123",
      password: "password123",
      role: :admin
    )
    sign_in @admin
    @user = users(:one)
  end

  test "show page renders the membership status card with the current tier" do
    get user_url(@user)
    assert_response :success

    assert_select "h2", "Membership Status"
    assert_includes response.body, "Silver"
    assert_includes response.body, "Current membership level"
  end

  test "show page shows how much more spend is needed for the next tier" do
    get user_url(@user)
    assert_response :success

    assert_includes response.body, "$500.00"
    assert_includes response.body, "more this year to reach"
    assert_includes response.body, "Gold"
  end

  test "show page indicates the member is at the highest tier when there is no next tier" do
    get user_url(users(:two))
    assert_response :success

    assert_includes response.body, "You have reached the highest membership level"
  end

  test "edit page renders the update form with profile fields" do
    get edit_user_url(@user)
    assert_response :success

    assert_select "input[name='user[full_name]']"
    assert_select "input[name='user[email]']"
    assert_select "input[name='user[phone]']"
    assert_select "input[name='user[location]']"
    assert_select "input[name='user[avatar]'][type='file']"
    assert_select "select[name='user[role]']"
    assert_select "select[name='user[status]']"
    assert_select "select[name='user[member_tier_id]']"
    assert_select "input[name='user[year_spend]']"
    assert_select "input[type='submit'][value='Update user']"
  end

  test "edit page does not expose a password field" do
    get edit_user_url(@user)
    assert_response :success

    assert_select "input[name='user[password]']", count: 0
    assert_select "input[name='user[password_confirmation]']", count: 0
  end

  test "edit page previews an attached avatar" do
    png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    @user.avatar.attach(io: StringIO.new(Base64.decode64(png)), filename: "avatar.png", content_type: "image/png")

    get edit_user_url(@user)
    assert_response :success
    assert_includes response.body, "Current avatar for John Doe"
  end

  test "should update user profile information" do
    patch user_url(@user), params: {
      user: {
        full_name: "Updated User",
        email: @user.email,
        phone: @user.phone,
        location: "Updated Location",
        avatar: fixture_file_upload("test/fixtures/files/avatar.png", "image/png")
      }
    }

    assert_redirected_to user_url(@user)
    @user.reload
    assert_equal "Updated User", @user.full_name
    assert_equal "Updated Location", @user.location
    assert @user.avatar.attached?
    assert_equal "avatar.png", @user.avatar.filename.to_s
  end

  test "admin can update administrative fields" do
    patch user_url(@user), params: {
      user: {
        full_name: @user.full_name,
        email: @user.email,
        phone: @user.phone,
        role: "customer",
        status: true,
        year_spend: 250.0
      }
    }

    assert_response :redirect
    @user.reload
    assert_predicate @user, :customer?
    assert @user.status, "status should be updated to active"
    assert_equal 250.0, @user.year_spend
  end

  # Staff directory (admin/users) -------------------------------------------

  test "index lists all users including admins and customers" do
    get admin_users_url
    assert_response :success

    # Every user in the directory should be displayed: admins, staff and customers.
    assert_select "tbody tr", count: User.count
    assert_select "tbody tr", text: /Admin User/
    assert_select "tbody tr", text: /John Doe/
    assert_select "tbody tr", text: /Jane Smith/
  end

  test "index does not let a non-admin see the staff directory" do
    sign_out @admin
    sign_in users(:one) # inventory_manager (non-admin)
    get admin_users_url
    assert_response :forbidden
  end

  test "admin can change a user's role from the directory dropdown" do
    # Simulate the inline role dropdown form in the staff directory.
    patch user_url(@user), params: {
      back_to_directory: "true",
      user: { role: "kitchen_staff" }
    }

    assert_redirected_to admin_users_url
    @user.reload
    assert_predicate @user, :kitchen_staff?
  end

  test "admin can destroy a user and is redirected back to the directory" do
    victim = User.create!(
      full_name: "To Be Deleted",
      email: "doomed@example.com",
      phone: "5550009999",
      password: "password123",
      role: :waiter
    )

    assert_difference("User.count", -1) do
      delete user_url(victim)
    end

    assert_redirected_to admin_users_url
    assert_equal "To Be Deleted was successfully removed.", flash[:notice]
    assert_not User.exists?(victim.id)
  end

  test "admin cannot destroy their own account" do
    assert_no_difference("User.count") do
      delete user_url(@admin)
    end

    assert_response :forbidden
  end

  test "directory delete button includes a confirmation notice" do
    get admin_users_url
    assert_response :success

    assert_select "form[action='#{user_path(@user)}'][method='post'] button[type='submit']",
                  text: "Delete", count: 1
    assert_includes response.body,
                    "data-turbo-confirm=\"Are you sure you want to permanently delete #{@user.full_name}? This action cannot be undone.\""
  end
end
