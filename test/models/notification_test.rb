require "test_helper"
require "turbo/broadcastable/test_helper"

class NotificationTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "broadcasts a prepend and a badge update to the recipient's stream on create" do
    recipient = users(:one)

    assert_turbo_stream_broadcasts recipient, count: 2 do
      Notification.create!(recipient: recipient, title: "Table ready", body: "Your table 4 is ready.")
    end
  end

  test "prepends the new notification into the notifications list" do
    recipient = users(:one)

    streams = capture_turbo_stream_broadcasts recipient do
      Notification.create!(recipient: recipient, title: "Promotion", body: "50% off desserts this weekend.")
    end

    assert_equal "prepend", streams.first["action"]
    assert_equal "notifications-list", streams.first["target"]
    assert_includes streams.first.to_html, "Promotion"
  end

  test "updates the header bell badge after delivering" do
    recipient = users(:one)

    streams = capture_turbo_stream_broadcasts recipient do
      Notification.create!(recipient: recipient, title: "New", body: "Something new.")
    end

    assert_equal "replace", streams.second["action"]
    assert_equal "notification-badge", streams.second["target"]
  end

  test "redirect_url can be omitted for normal notifications without a related page" do
    notification = Notification.create!(recipient: users(:one), title: "Just a notice")
    assert_nil notification.redirect_url
  end

  test "redirect_url is persisted when present" do
    notification = Notification.create!(recipient: users(:one), title: "Table ready",
      redirect_url: "https://example.com/orders/4")
    assert_equal "https://example.com/orders/4", notification.redirect_url
  end

  test "redirect_url accepts a path (internal route)" do
    notification = Notification.create!(recipient: users(:one), title: "Seat ready", redirect_url: "/tables/2")
    assert_equal "/tables/2", notification.redirect_url
  end

  test "redirect_url validates as a URL or a leading-slash path" do
    notification = Notification.new(recipient: users(:one), title: "Test", redirect_url: "/orders/9")
    assert notification.valid?

    notification.redirect_url = "not-a-uri"
    assert_not notification.valid?
    assert_includes notification.errors[:redirect_url], "must be a valid URL (e.g. https://example.com/orders/5) or a path (e.g. /orders/5)"
  end
end
