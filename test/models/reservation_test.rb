require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @customer = users(:one)
    @bookable = Table.create!(
      area: areas(:one), table_type: table_types(:one),
      table_number: "R1", capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )
  end

  def build_reservation(attrs = {})
    defaults = {
      user: @customer, table: @bookable, guest_name: "Jane",
      guest_phone: "0812345678", status: :pending,
      reservation_date: Date.current + 1, reservation_time: "19:00"
    }
    Reservation.new(defaults.merge(attrs))
  end

  test "meal slots are the configured on-the-hour starts" do
    date = Date.new(2026, 9, 10)
    assert_equal [11, 13, 17, 19, 21], Reservation.meal_slots_for(date).map(&:hour)
  end

  test "a reservation holds a 2-hour window around its start time" do
    r = build_reservation
    r.reservation_time = "17:00"
    r.save!

    assert r.holds_table_now?(r.slot_start)
    assert r.holds_table_now?(r.slot_start + 30.minutes)
    assert_not r.holds_table_now?(r.slot_start - 1.minute)
    assert_not r.holds_table_now?(r.slot_end) # end is exclusive
    assert_not r.holds_table_now?(r.slot_start + 3.hours)
  end

  test "a future reservation does not mark its table reserved" do
    r = build_reservation
    r.save!
    assert r.table.reload.available?
  end

  test "a reservation active right now marks the table reserved" do
    travel_to Time.zone.local(2026, 9, 10, 11, 30) do
      r = build_reservation(reservation_date: Date.current, reservation_time: "11:00")
      r.save!
      assert r.table.reload.reserved?
    end
  end

  test "two non-overlapping slots on the same table & date are allowed" do
    build_reservation(reservation_time: "17:00", guest_phone: "0812345671").save!
    second = build_reservation(reservation_time: "19:00", guest_phone: "0812345679")
    assert second.valid?, second.errors.full_messages.join(", ")
  end

  test "the same slot on the same table & date is rejected" do
    build_reservation(reservation_time: "17:00", guest_phone: "0812345671").save!
    conflict = build_reservation(reservation_time: "17:00", guest_phone: "0812345679")
    assert_not conflict.valid?
    assert conflict.errors[:reservation_time].any?
  end

  test "the same slot on a different date is allowed" do
    build_reservation(reservation_time: "17:00", guest_phone: "0812345671").save!
    later = build_reservation(reservation_date: Date.current + 2, reservation_time: "17:00", guest_phone: "0812345679")
    assert later.valid?, later.errors.full_messages.join(", ")
  end

  test "approving keeps the table reserved and rejecting frees it" do
    travel_to Time.zone.local(2026, 9, 10, 11, 30) do
      r = build_reservation(reservation_date: Date.current, reservation_time: "11:00")
      r.save!
      assert r.table.reload.reserved?

      r.update!(status: :approved)
      assert r.table.reload.reserved?

      r.update!(status: :rejected)
      assert r.table.reload.available?
    end
  end

  test "checking in an active reservation marks the table occupied" do
    travel_to Time.zone.local(2026, 9, 10, 11, 30) do
      r = build_reservation(reservation_date: Date.current, reservation_time: "11:00", status: :approved)
      r.save!
      assert r.table.reload.reserved?

      r.update!(status: :checked_in)
      assert r.table.reload.occupied?
    end
  end

  test "completing a checked-in reservation frees the table" do
    travel_to Time.zone.local(2026, 9, 10, 11, 30) do
      r = build_reservation(reservation_date: Date.current, reservation_time: "11:00", status: :checked_in)
      r.save!
      assert r.table.reload.occupied?

      r.update!(status: :completed)
      assert r.table.reload.available?
    end
  end

  test "an out-of-service table has no available slots" do
    @bookable.update!(status: :out_of_service)
    assert_empty Reservation.available_slots(@bookable, Date.current + 1)
  end

  test "available_slots reports non-overlapping slots as free" do
    build_reservation(reservation_time: "17:00", guest_phone: "0812345671").save!
    free = Reservation.available_slots(@bookable, Date.current + 1)
    assert_equal [11, 13, 19, 21], free.map(&:hour)
  end

  test "an occupied table cannot be booked for today's slot" do
    @bookable.update!(status: :occupied)
    r = build_reservation(reservation_date: Date.current, reservation_time: "19:00")
    assert_not r.valid?
    assert r.errors[:table].any?
  end
end
