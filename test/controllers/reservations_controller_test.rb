require "test_helper"

class ReservationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @reservation = reservations(:one)
    @customer = users(:one)

    # Available tables (the fixture tables are "occupied" and can't be booked).
    @bookable = Table.create!(
      area: areas(:one), table_type: table_types(:one),
      table_number: "AV1", capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )
    @bookable2 = Table.create!(
      area: areas(:one), table_type: table_types(:one),
      table_number: "AV2", capacity: 4, shape: :square, status: :available,
      pos_x: 0, pos_y: 0, rotation: 0, width: 100, height: 100
    )

    # Log in so the create action can associate the reservation with a user.
    # Users are always signed in when they make a reservation.
    sign_in @customer
  end

  def valid_reservation_params(table: @bookable, guest_name: "Jane Doe", phone: "0812345678")
    {
      reservation: {
        guest_name: guest_name,
        guest_phone: phone,
        reservation_date: Date.today,
        reservation_time: "19:30",
        table_id: table.id,
        note: "Window seat please"
      }
    }
  end

  test "should get index" do
    get reservations_url
    assert_response :success
  end

  test "admin management page shows a reservation table with status actions" do
    sign_in users(:admin)

    Reservation.create!(user: @customer, table: @bookable,
      guest_name: "Pending Guest", guest_phone: "0812345678", status: :pending)

    get admin_reservations_path
    assert_response :success

    assert_select "table thead th", text: "Actions"
    assert_select "button", text: "Approve"
    assert_select "button", text: "Reject"
    assert_select "input[name='reservation[status]'][type='hidden'][value='approved']", count: 1
  end

  test "receptionist can view the admin reservations management page" do
    sign_in users(:receptionist)

    get admin_reservations_path
    assert_response :success
  end

  test "a customer cannot access the admin reservations management page" do
    get admin_reservations_path
    assert_response :forbidden
  end

  test "should get new with the customer form (no status field)" do
    get new_reservation_url
    assert_response :success

    assert_select "form" do
      assert_select "input[name='reservation[guest_name]']"
      assert_select "input[name='reservation[guest_phone]']"
      assert_select "input[name='reservation[reservation_date]']"
      assert_select "input[name='reservation[reservation_time]']"
      assert_select "textarea[name='reservation[note]']"
      # The table is chosen by clicking the floor plan, not a dropdown.
      assert_select "select[name='reservation[table_id]']", count: 0
      # Status is managed separately by admins/receptionists only.
      assert_select "[name='reservation[status]']", count: 0
    end
  end

  test "new form pre-selects the table clicked on the floor plan" do
    get new_reservation_url, params: { table_id: @bookable.id }
    assert_response :success

    assert_select "input[name='reservation[table_id]'][type='hidden'][value='#{@bookable.id}']"
    assert_select "select[name='reservation[table_id]']", count: 0
  end

  test "should create reservation and reserve the table" do
    assert_difference("Reservation.count") do
      post reservations_url, params: valid_reservation_params
    end

    reservation = Reservation.last
    assert_equal @customer.id, reservation.user_id
    assert_equal "pending", reservation.status
    # Booking a table sets its status to reserved so it can't be booked again.
    assert @bookable.reload.reserved?
    assert_redirected_to reservations_url
  end

  test "should allow creating a reservation without a signed-in user (user_id null)" do
    sign_out @customer

    assert_difference("Reservation.count") do
      post reservations_url, params: valid_reservation_params(table: @bookable2, guest_name: "Walk-in Guest", phone: "0892776511")
    end

    assert_redirected_to reservations_url
    assert_nil Reservation.last.user_id
  end

  test "should show reservation" do
    get reservation_url(@reservation)
    assert_response :success
  end

  test "should not book a table that is already reserved" do
    Reservation.create!(user: @customer, table: @bookable, guest_name: "First", guest_phone: "0812345678",
      reservation_date: Date.today, reservation_time: "19:00", status: :pending)

    assert_no_difference("Reservation.count") do
      post reservations_url, params: valid_reservation_params(guest_name: "Second Guest")
    end

    assert_response :unprocessable_content
  end
test "should get edit with the customer form (no status field)" do
    get edit_reservation_url(@reservation)
    assert_response :success

    assert_select "form" do
      assert_select "input[name='reservation[guest_name]']"
      assert_select "input[name='reservation[reservation_date]']"
      assert_select "input[name='reservation[table_id]'][type='hidden'][value='#{@reservation.table_id}']"
      assert_select "select[name='reservation[table_id]']", count: 0
      assert_select "select[name='reservation[status]']", count: 0
    end
  end

  test "should update reservation without touching status" do
    reservation = Reservation.create!(
      guest_name: "Jane Doe", guest_phone: "0812345678", user: @customer,
      table: @bookable, reservation_date: Date.today, reservation_time: "19:30", status: :pending
    )

    patch reservation_url(reservation), params: {
      reservation: {
        guest_name: "Jane Updated",
        guest_phone: "0812345679",
        reservation_date: Date.today,
        reservation_time: "20:00",
        table_id: @bookable.id
      }
    }

    assert_redirected_to reservation_url(reservation)
    reservation.reload
    assert_equal "Jane Updated", reservation.guest_name
    assert_equal "pending", reservation.status # unchanged by the customer form
  end

  test "should destroy reservation" do
    assert_difference("Reservation.count", -1) do
      delete reservation_url(@reservation)
    end

    assert_redirected_to reservations_url
  end

  # Staff-only status transitions -------------------------------------------

  test "admin approving a pending reservation keeps the table reserved" do
    pending = Reservation.create!(guest_name: "Jane", guest_phone: "0812345678",
      user: @customer, table: @bookable, status: :pending)
    assert pending.table.reserved?

    sign_in users(:admin)

    patch update_status_admin_reservation_path(pending), params: { reservation: { status: :approved } }

    assert_redirected_to admin_reservations_path
    assert pending.reload.approved?
    assert pending.table.reload.reserved? # stays reserved after approval
  end

  test "admin rejecting a reservation frees the table to available" do
    pending = Reservation.create!(guest_name: "Jane", guest_phone: "0812345678",
      user: @customer, table: @bookable, status: :pending)
    assert pending.table.reload.reserved?

    sign_in users(:admin)

    patch update_status_admin_reservation_path(pending), params: { reservation: { status: :rejected } }

    assert_redirected_to admin_reservations_path
    assert pending.reload.rejected?
    assert pending.table.reload.available? # freed after rejection
  end

  test "admin checking in an approved reservation marks the table occupied" do
    approved = Reservation.create!(guest_name: "Jane", guest_phone: "0812345678",
      user: @customer, table: @bookable, status: :approved)
    assert approved.table.reserved?

    sign_in users(:admin)

    patch update_status_admin_reservation_path(approved), params: { reservation: { status: :checked_in } }

    assert_redirected_to admin_reservations_path
    assert approved.reload.checked_in?
    assert approved.table.reload.occupied? # table becomes occupied on check-in
  end

  test "completing a checked-in reservation frees the table to available" do
    checked_in = Reservation.create!(guest_name: "Jane", guest_phone: "0812345678",
      user: @customer, table: @bookable, status: :checked_in)
    assert checked_in.table.reload.occupied?

    sign_in users(:admin)

    patch update_status_admin_reservation_path(checked_in), params: { reservation: { status: :completed } }

    assert_redirected_to admin_reservations_path
    assert checked_in.reload.completed?
    assert checked_in.table.reload.available? # freed back to available
  end

  test "a customer cannot update a reservation status" do
    # A non-staff user (customer role) is not authorized to change status.
    patch update_status_admin_reservation_path(@reservation), params: { reservation: { status: :approved } }
    assert_response :forbidden
  end
end
