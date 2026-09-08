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
end
