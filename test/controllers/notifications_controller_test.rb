require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @notification = notifications(:one)
  end

  test "should get index" do
    get notifications_url
    assert_response :success
  end

  test "should get new" do
    get new_notification_url
    assert_response :success
  end

  test "should create notification" do
    assert_difference("Notification.count") do
      post notifications_url, params: { notification: {} }
    end

    assert_redirected_to notification_url(Notification.last)
  end

  test "should show notification" do
    get notification_url(@notification)
    assert_response :success
  end

  test "should get edit" do
    get edit_notification_url(@notification)
    assert_response :success
  end

  test "should update notification" do
    patch notification_url(@notification), params: { notification: {} }
    assert_redirected_to notification_url(@notification)
  end

  test "should destroy notification" do
    assert_difference("Notification.count", -1) do
      delete notification_url(@notification)
    end

    assert_redirected_to notifications_url
  end

  test "index renders notification card as a clickable link for external redirect_url" do
    sign_in users(:one)
    get notifications_url
    assert_response :success

    # notification one carries an external redirect_url (full URL)
    assert_select "a[href='https://example.com/orders/1'][target='_blank'][rel='noopener noreferrer']"
  end

  test "index renders notification card as a clickable link for internal redirect_url" do
    sign_in users(:two)
    get notifications_url
    assert_response :success

    # notification two carries an internal redirect_url (path, no target)
    assert_select "a[href='/orders/2']" do
      assert_select "[target]", count: 0
    end
  end

  test "index does not render a link for notifications without redirect_url" do
    sign_in users(:one)
    Notification.create!(recipient: users(:one), title: "Just a notice",
      body: "No related page.")
    get notifications_url
    assert_response :success

    # the notification without redirect_url must render as a plain <article>,
    # not wrapped in an <a>
    assert_select "article" do |articles|
      plain = articles.detect { |a| a.content.include?("No related page.") }
      assert plain, "expected a plain card for the notification without redirect_url"
      assert_not plain.at_css("a"), "should not be wrapped in a link"
    end
  end
end
