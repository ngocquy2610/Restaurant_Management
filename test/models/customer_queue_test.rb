require "test_helper"

class CustomerQueueTest < ActiveSupport::TestCase
  test "enqueue_walk_in! sets the staff member as user and leaves the table unassigned" do
    staff = users(:receptionist)

    queue = CustomerQueueManager.enqueue_walk_in!(
      { guest_name: "Walk-in Guest", guest_phone: "0867867307" },
      staff: staff
    )

    assert queue.persisted?
    assert_not_nil queue.user_id
    assert_equal staff, queue.user
    assert_nil queue.table_id
    assert_equal "waiting", queue.status
  end
end
