require "test_helper"

# End-to-end rendering checks for every place a customer review is displayed:
# the reservation detail page, the order detail page, the public menu page and
# the customer profile (dining history).
class ReviewDisplayTest < ActionDispatch::IntegrationTest
  setup do
    @customer = users(:customer)

    @table = Table.create!(
      area: areas(:one), table_type: table_types(:one), table_number: "RD1",
      capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )
    @reservation = Reservation.create!(
      user: @customer, table: @table, guest_name: "Diner", guest_phone: "0812345678",
      status: :completed, reservation_date: Date.current - 1, reservation_time: "19:00"
    )
    @order = Order.create!(table: @table, reservation: @reservation, status: :completed)

    @meal_review = Review.create!(reservation: @reservation, rating: 5, comment: "Superb tasting menu")
    @restaurant_review = Review.create!(
      reservation: @reservation, review_type: :restaurant, rating: 4, comment: "Elegant dining room"
    )
  end

  test "the reservation page shows the meal review for that visit" do
    sign_in @customer

    get reservation_path(@reservation)

    assert_response :success
    assert_match "Your review of this meal", response.body
    assert_match "Superb tasting menu", response.body
  end

  test "the order page shows the meal review of its reservation" do
    sign_in @customer

    get order_path(@order)

    assert_response :success
    assert_match "Customer review", response.body
    assert_match "Superb tasting menu", response.body
  end

  test "the public menu page shows the restaurant review wall only" do
    get menus_path

    assert_response :success
    assert_match "Guest reviews", response.body
    assert_match "Elegant dining room", response.body
    assert_no_match "Superb tasting menu", response.body
  end

  test "the customer profile marks the visit as reviewed" do
    sign_in @customer

    get user_path(@customer)

    assert_response :success
    assert_match "You reviewed this meal", response.body
  end
end
