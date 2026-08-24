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

  test "current_member_tier returns the assigned tier" do
    user = users(:one)
    assert_equal member_tiers(:silver), user.current_member_tier
  end

  test "current_member_tier falls back to the lowest tier when none is assigned" do
    user = users(:one)
    user.update_column(:member_tier_id, nil)

    assert_equal member_tiers(:bronze), user.current_member_tier
  end

  test "next_member_tier returns the tier above the current one" do
    user = users(:one)
    assert_equal member_tiers(:gold), user.next_member_tier
  end

  test "next_member_tier is nil at the highest tier" do
    user = users(:two)
    assert_nil user.next_member_tier
  end

  test "amount_to_next_member_tier is the remaining spend for the next tier" do
    user = users(:one) # silver at $700 spend, next tier gold requires $1,200
    assert_equal 500, user.amount_to_next_member_tier
  end

  test "updating year_spend recalculates and assigns the matching member tier" do
    user = users(:one)
    user.update!(year_spend: 1500)

    assert_equal member_tiers(:gold), user.reload.member_tier
  end
end