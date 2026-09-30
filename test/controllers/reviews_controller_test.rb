require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = users(:customer)        # role: customer
    @other_customer = users(:one)       # role: inventory_manager (not staff for reviews)

    @table = Table.create!(
      area: areas(:one), table_type: table_types(:one), table_number: "RC1",
      capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )
    @other_table = Table.create!(
      area: areas(:one), table_type: table_types(:one), table_number: "RC2",
      capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )

    @reservation = finished_reservation(user: @customer, table: @table)
    @other_reservation = finished_reservation(user: @other_customer, table: @other_table, guest_name: "Other")
  end

  def finished_reservation(user:, table:, guest_name: "Guest", phone: "0812345678")
    Reservation.create!(
      user: user, table: table, guest_name: guest_name, guest_phone: phone,
      status: :completed, reservation_date: Date.current - 1, reservation_time: "19:00"
    )
  end

  # ---------- public wall ----------

  test "index is visible to signed out visitors" do
    Review.create!(reservation: @reservation, review_type: :restaurant, rating: 4, comment: "Great room")

    get reviews_url

    assert_response :success
    assert_match "Great room", response.body
  end

  test "index can be filtered to restaurant reviews only" do
    Review.create!(reservation: @reservation, rating: 5, comment: "Meal only")
    Review.create!(reservation: @reservation, review_type: :restaurant, rating: 2, comment: "Room only")

    get reviews_url(type: "restaurant")

    assert_response :success
    assert_match "Room only", response.body
    assert_no_match "Meal only", response.body
  end

  test "show renders a review publicly" do
    review = Review.create!(reservation: @reservation, rating: 4, comment: "Nice")

    get review_url(review)

    assert_response :success
  end

  # ---------- meal reviews ----------

  test "a guest is sent to the login page when opening the review form" do
    get new_review_url(reservation_id: @reservation.id, review_type: "meal")

    assert_redirected_to new_user_session_path
  end

  test "a customer can open the meal review form for their own finished visit" do
    sign_in @customer

    get new_review_url(reservation_id: @reservation.id, review_type: "meal")

    assert_response :success
    assert_match "How was your meal?", response.body
  end

  test "an already reviewed meal redirects to the existing review" do
    review = Review.create!(reservation: @reservation, rating: 4, comment: "Done")
    sign_in @customer

    get new_review_url(reservation_id: @reservation.id, review_type: "meal")

    assert_redirected_to review_path(review)
  end

  test "creating a meal review attaches it to the reservation and its customer" do
    sign_in @customer

    assert_difference("Review.count") do
      post reviews_url, params: {
        review: { reservation_id: @reservation.id, review_type: "meal", rating: 5, comment: "Delicious" }
      }
    end

    review = Review.last
    assert review.meal?
    assert_equal @reservation.id, review.reservation_id
    assert_equal @customer.id, review.user_id
    assert_equal 5, review.rating
    assert_redirected_to reservation_path(@reservation)
  end

  test "an out of range rating is rejected" do
    sign_in @customer

    assert_no_difference("Review.count") do
      post reviews_url, params: { review: { reservation_id: @reservation.id, rating: 0 } }
    end

    assert_response :unprocessable_content
    assert_select "#review_error_explanation"
  end

  test "a second review for the same meal is rejected" do
    Review.create!(reservation: @reservation, rating: 4, comment: "First")
    sign_in @customer

    assert_no_difference("Review.count") do
      post reviews_url, params: { review: { reservation_id: @reservation.id, rating: 5 } }
    end

    assert_response :unprocessable_content
    assert_match "You have already reviewed this meal.", response.body
  end

  test "a customer cannot review another customer's reservation" do
    sign_in @customer

    assert_no_difference("Review.count") do
      post reviews_url, params: { review: { reservation_id: @other_reservation.id, rating: 5 } }
    end

    assert_response :forbidden
  end

  test "an unfinished reservation cannot be reviewed" do
    upcoming = Reservation.create!(
      user: @customer, table: @table, guest_name: "Future", guest_phone: "0812345670",
      status: :approved, reservation_date: Date.current + 1, reservation_time: "11:00"
    )
    sign_in @customer

    post reviews_url, params: { review: { reservation_id: upcoming.id, rating: 5 } }

    assert_response :forbidden
  end

  # ---------- restaurant reviews ----------

  test "a customer can submit the one time restaurant review" do
    sign_in @customer

    assert_difference("Review.count") do
      post reviews_url, params: { review: { review_type: "restaurant", rating: 5, comment: "Beautiful room" } }
    end

    review = Review.last
    assert review.restaurant?
    assert_equal @customer.id, review.user_id
    assert_equal @reservation.id, review.reservation_id
    assert_redirected_to reviews_path(type: "restaurant")
  end

  test "the restaurant review can only be submitted once" do
    Review.create!(reservation: @reservation, review_type: :restaurant, rating: 4)
    sign_in @customer

    assert_no_difference("Review.count") do
      post reviews_url, params: { review: { review_type: "restaurant", rating: 5 } }
    end

    assert_response :unprocessable_content
    assert_match "You have already reviewed the restaurant.", response.body
  end

  test "a customer with no finished visit cannot review the restaurant" do
    sign_in users(:waiter)   # no reservations at all

    assert_no_difference("Review.count") do
      post reviews_url, params: { review: { review_type: "restaurant", rating: 5 } }
    end

    assert_response :forbidden
  end

  test "the restaurant entry point sends an eligible customer to the form" do
    sign_in @customer

    get restaurant_reviews_url

    assert_redirected_to new_review_path(review_type: "restaurant", reservation_id: @reservation.id)
  end

  test "the restaurant entry point sends ineligible customers back to the wall" do
    sign_in users(:waiter)

    get restaurant_reviews_url

    assert_redirected_to reviews_path
    assert_match "first completed visit", flash[:alert].to_s
  end

  # ---------- edit / delete ----------

  test "the owner can edit and delete their review" do
    review = Review.create!(reservation: @reservation, rating: 3, comment: "Okay")
    sign_in @customer

    get edit_review_url(review)
    assert_response :success

    patch review_url(review), params: { review: { rating: 5, comment: "Actually great" } }
    assert_redirected_to review_url(review)

    review.reload
    assert_equal 5, review.rating
    assert_equal "Actually great", review.comment

    assert_difference("Review.count", -1) { delete review_url(review) }
    assert_redirected_to reservation_path(@reservation)
  end

  test "another signed in customer cannot edit or delete a review" do
    review = Review.create!(reservation: @reservation, rating: 5, comment: "Mine")
    sign_in @other_customer

    get edit_review_url(review)
    assert_response :forbidden

    patch review_url(review), params: { review: { rating: 1 } }
    assert_response :forbidden

    assert_no_difference("Review.count") { delete review_url(review) }
    assert_response :forbidden
    assert_equal "Mine", review.reload.comment
  end

  test "a signed out visitor cannot modify a review" do
    review = Review.create!(reservation: @reservation, rating: 5)

    patch review_url(review), params: { review: { rating: 1 } }

    assert_redirected_to new_user_session_path
    assert_equal 5, review.reload.rating
  end
end
