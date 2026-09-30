require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @customer = users(:customer)

    @table = Table.create!(
      area: areas(:one), table_type: table_types(:one),
      table_number: "RV1", capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )
  end

  # A finished visit: completed, in the past, owned by a registered customer.
  def completed_reservation(overrides = {})
    defaults = {
      user: @customer, table: @table, guest_name: "Reviewer",
      guest_phone: "0812345678", status: :completed,
      reservation_date: Date.current - 1, reservation_time: "19:00"
    }
    Reservation.create!(defaults.merge(overrides))
  end

  test "defaults to a meal review and derives the customer from the reservation" do
    reservation = completed_reservation
    review = Review.create!(reservation: reservation, rating: 5, comment: "Excellent")

    assert review.meal?
    assert_equal reservation, review.reservation
    assert_equal @customer.id, review.user_id
    assert_equal @customer.full_name, review.reviewer_name
    assert_equal reservation.slot_start, review.meal_at
    assert_includes review.meal_label, "07:00 PM"
  end

  test "the meal slot is read live from the reservation, with no snapshot columns" do
    reservation = completed_reservation
    review = Review.create!(reservation: reservation, rating: 4)

    assert_not Review.column_names.include?("meal_date")
    assert_not Review.column_names.include?("meal_time")

    reservation.update_columns(reservation_date: Date.current - 2, reservation_time: "13:00")
    reservation.reload

    assert_equal reservation.slot_start, Review.find(review.id).meal_at
  end

  test "rating must be an integer between 1 and 5" do
    reservation = completed_reservation

    [0, 6, 3.5, nil].each do |bad|
      review = Review.new(reservation: reservation, rating: bad)
      assert_not review.valid?, "expected rating #{bad.inspect} to be invalid"
    end

    assert Review.new(reservation: reservation, rating: 3).valid?
  end

  test "comment is optional and capped at 1000 characters" do
    reservation = completed_reservation

    assert Review.new(reservation: reservation, rating: 4, comment: nil).valid?
    assert Review.new(reservation: reservation, rating: 4, comment: "a" * 1000).valid?
    assert_not Review.new(reservation: reservation, rating: 4, comment: "a" * 1001).valid?
  end

  test "a meal can only be reviewed once" do
    reservation = completed_reservation
    Review.create!(reservation: reservation, rating: 5, comment: "First")

    duplicate = Review.new(reservation: reservation, rating: 3)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "You have already reviewed this meal."
  end

  test "a customer may review a meal and the restaurant once each" do
    reservation = completed_reservation
    Review.create!(reservation: reservation, rating: 5)

    restaurant = Review.new(reservation: reservation, review_type: :restaurant, rating: 4)
    assert restaurant.valid?, restaurant.errors.full_messages.join(", ")
    restaurant.save!

    second = Review.new(reservation: reservation, review_type: :restaurant, rating: 2)
    assert_not second.valid?
    assert_includes second.errors[:base], "You have already reviewed the restaurant."
  end

  test "another customer may still review the restaurant" do
    reservation = completed_reservation
    Review.create!(reservation: reservation, review_type: :restaurant, rating: 4)

    other = completed_reservation(user: users(:one))
    assert Review.new(reservation: other, review_type: :restaurant, rating: 5).valid?
  end

  test "pending, rejected, cancelled and upcoming visits cannot be reviewed" do
    unreviewable = {
      pending: completed_reservation(status: :pending, reservation_date: Date.current + 1, reservation_time: "11:00"),
      rejected: completed_reservation(status: :rejected, reservation_date: Date.current - 1, reservation_time: "13:00"),
      cancelled: completed_reservation(status: :cancelled, reservation_date: Date.current - 1, reservation_time: "17:00"),
      upcoming: completed_reservation(status: :approved, reservation_date: Date.current + 1, reservation_time: "13:00")
    }

    unreviewable.each do |state, reservation|
      review = Review.new(reservation: reservation, rating: 5)
      assert_not review.valid?, "expected a #{state} reservation to be unreviewable"
      assert_includes review.errors[:reservation], "cannot be reviewed yet"
    end
  end

  test "a past meal is reviewable even if staff never completed the visit" do
    past = completed_reservation(status: :checked_in)
    review = Review.new(reservation: past, rating: 5)

    assert review.valid?, review.errors.full_messages.join(", ")
  end

  test "reservations without a customer account cannot be reviewed" do
    guest = completed_reservation(user: nil)
    review = Review.new(reservation: guest, rating: 4)

    assert_not review.valid?
    assert_nil review.user_id
    assert_includes review.errors[:reservation], "cannot be reviewed yet"
  end

  test "reviewer name falls back to the guest name when there is no account" do
    guest = completed_reservation(user: nil, guest_name: "Walk-in Wendy")
    review = Review.new(reservation: guest, rating: 4)

    assert_nil review.customer
    assert_equal "Walk-in Wendy", review.reviewer_name
  end

  test "the derived customer must match the reservation" do
    reservation = completed_reservation
    review = Review.new(reservation: reservation, rating: 4, user_id: users(:two).id)

    assert_not review.valid?
    assert_includes review.errors[:user_id], "must match the reservation's customer"
  end

  test "for_customer scopes by type and average_rating averages the scope" do
    reservation = completed_reservation
    Review.create!(reservation: reservation, rating: 5, comment: "Meal")
    Review.create!(reservation: reservation, review_type: :restaurant, rating: 3, comment: "Room")

    assert_equal 1, Review.for_customer(@customer, :meal).count
    assert_equal 1, Review.for_customer(@customer, :restaurant).count
    assert_equal 0, Review.for_customer(users(:two), :meal).count
    assert_in_delta 4.0, Review.average_rating(Review.where(reservation_id: reservation.id)), 0.01
  end

  test "the database rejects a second meal review for the same reservation" do
    reservation = completed_reservation
    Review.create!(reservation: reservation, rating: 4)

    assert_raises(ActiveRecord::RecordNotUnique) do
      Review.transaction(requires_new: true) do
        Review.insert!({
          reservation_id: reservation.id, user_id: @customer.id,
          review_type: 0, rating: 3,
          created_at: Time.zone.now, updated_at: Time.zone.now
        })
      end
    end
  end

  test "the database rejects a second restaurant review for the same customer" do
    reservation = completed_reservation
    Review.create!(reservation: reservation, review_type: :restaurant, rating: 4)

    assert_raises(ActiveRecord::RecordNotUnique) do
      Review.transaction(requires_new: true) do
        Review.insert!({
          reservation_id: reservation.id, user_id: @customer.id,
          review_type: 1, rating: 5,
          created_at: Time.zone.now, updated_at: Time.zone.now
        })
      end
    end
  end

  test "the database rejects ratings outside 1..5" do
    reservation = completed_reservation

    assert_raises(ActiveRecord::StatementInvalid) do
      Review.transaction(requires_new: true) do
        Review.connection.execute(
          "INSERT INTO reviews (reservation_id, review_type, rating, created_at, updated_at) " \
          "VALUES (#{reservation.id}, 0, 9, NOW(), NOW())"
        )
      end
    end
  end
end
