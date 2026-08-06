require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "jti is automatically set on create" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      full_name: "Test User",
      phone: "1112223333"
    )

    assert_nil user.jti
    user.save!
    assert_not_nil user.jti
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, user.jti)
  end

  test "existing jti is not overwritten on create" do
    existing_jti = SecureRandom.uuid
    user = User.new(
      email: "test2@example.com",
      password: "password123",
      full_name: "Test User 2",
      phone: "4445556666",
      jti: existing_jti
    )

    user.save!
    assert_equal existing_jti, user.jti
  end
end