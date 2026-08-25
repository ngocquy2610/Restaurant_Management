require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "renders slideshow for published promotions with images" do
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
    assert_match "Summer Feast", response.body
    assert_match "Happy Hour", response.body
    assert_select "button[data-action='promo-slider#next']", 1
    assert_select "button[data-action='promo-slider#prev']", 1
    assert_select "button[data-action='promo-slider#dot']", 2
  end

  test "does not show slider when there are no published promotions" do
    get root_url
    assert_response :success
    assert_select "[data-controller='promo-slider']", 0
  end
end
