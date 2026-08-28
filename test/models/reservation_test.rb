require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  setup do
    @customer = users(:one)
    @bookable = Table.create!(
      area: areas(:one), table_type: table_types(:one),
      table_number: "R1", capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )
  end

  test "creating a pending reservation marks the table as reserved" do
    reservation = Reservation.create!(user: @customer, table: @bookable,
      guest_name: "Jane", guest_phone: "0812345678", status: :pending)

    assert reservation.pending?
    assert @bookable.reload.reserved?
  end

  test "approving keeps the table reserved and rejecting frees it" do
    reservation = Reservation.create!(user: @customer, table: @bookable,
      guest_name: "Jane", guest_phone: "0812345678", status: :pending)
    assert @bookable.reload.reserved?

    # Approve -> still reserved.
    reservation.update!(status: :approved)
    assert @bookable.reload.reserved?

    # Reject -> freed to available.
    reservation.update!(status: :rejected)
    assert @bookable.reload.available?
  end

  test "checking in an approved reservation marks the table occupied" do
    reservation = Reservation.create!(user: @customer, table: @bookable,
      guest_name: "Jane", guest_phone: "0812345678", status: :approved)
    assert @bookable.reload.reserved?

    reservation.update!(status: :checked_in)
    assert @bookable.reload.occupied?
  end

  test "a table cannot be double-booked while a reservation is active" do
    Reservation.create!(user: @customer, table: @bookable,
      guest_name: "First", guest_phone: "0812345678", status: :pending)

    second = Reservation.new(user: @customer, table: @bookable,
      guest_name: "Second", guest_phone: "0812345679", status: :pending)

    assert_not second.valid?
    assert second.errors[:table].any?
  end

  test "a completed status frees the table back to available" do
    reservation = Reservation.create!(user: @customer, table: @bookable,
      guest_name: "Jane", guest_phone: "0812345678", status: :approved)
    assert @bookable.reload.reserved?

    reservation.update!(status: :completed)
    assert @bookable.reload.available?
  end

  test "an occupied table cannot be booked" do
    @bookable.update!(status: :occupied)

    reservation = Reservation.new(user: @customer, table: @bookable,
      guest_name: "Jane", guest_phone: "0812345678", status: :pending)

    assert_not reservation.valid?
    assert reservation.errors[:table].any?
  end
end
