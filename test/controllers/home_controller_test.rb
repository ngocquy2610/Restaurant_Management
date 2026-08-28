require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "renders slideshow with default cover first and active promotions" do
    promo = Promotion.create!(
      name: "Summer Feast",
      discount_type: "percentage",
      discount_value: 20,
      start_date: Time.current,
      end_date: 7.days.from_now,
      status: "published"
    )
    promo.image.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
                       filename: "promo.png", content_type: "image/png")

    second = Promotion.create!(
      name: "Happy Hour",
      discount_type: "fix_amount",
      discount_value: 5,
      start_date: Time.current,
      end_date: 7.days.from_now,
      status: "published"
    )
    second.image.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
                        filename: "promo2.png", content_type: "image/png")

    get root_url
    assert_response :success

    assert_select "[data-controller='promo-slider']", 1
    # Default cover is always the first slide.
    assert_match "default_cover.jpeg", response.body
    assert_match "Welcome to Lumière Dining", response.body

    assert_match "Summer Feast", response.body
    assert_match "Happy Hour", response.body
    assert_select "button[data-action='promo-slider#next']", 1
    assert_select "button[data-action='promo-slider#prev']", 1
    # Default cover dot + one dot per promotion.
    assert_select "button[data-action='promo-slider#dot']", 3
  end

  test "always shows default cover slider even without published promotions" do
    get root_url
    assert_response :success

    assert_select "[data-controller='promo-slider']", 1
    assert_match "default_cover.jpeg", response.body
    assert_select "button[data-action='promo-slider#dot']", 1
    assert_select "button[data-action='promo-slider#next']", 0
    assert_select "button[data-action='promo-slider#prev']", 0
  end

  test "does not show promotions that are outside their active date window" do
    expired = Promotion.create!(
      name: "Expired Deal",
      discount_type: "percentage",
      discount_value: 10,
      start_date: 10.days.ago,
      end_date: 1.day.ago,
      status: "published"
    )
    expired.image.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
                         filename: "expired.png", content_type: "image/png")

    upcoming = Promotion.create!(
      name: "Upcoming Deal",
      discount_type: "fix_amount",
      discount_value: 3,
      start_date: 1.day.from_now,
      end_date: 10.days.from_now,
      status: "published"
    )
    upcoming.image.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
                          filename: "upcoming.png", content_type: "image/png")

    get root_url
    assert_response :success

    assert_select "[data-controller='promo-slider']", 1
    refute_match "Expired Deal", response.body
    refute_match "Upcoming Deal", response.body
    # Only the default cover remains; no next/prev controls.
    assert_select "button[data-action='promo-slider#dot']", 1
    assert_select "button[data-action='promo-slider#next']", 0
    assert_select "button[data-action='promo-slider#prev']", 0
  end
end
