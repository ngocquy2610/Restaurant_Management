require "test_helper"

class Inventory::RestockTasksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:admin) }

  test "index renders" do
    get inventory_restock_tasks_url
    assert_response :success
  end

  test "index filters by status" do
    get inventory_restock_tasks_url(status: "pending")
    assert_response :success
  end

  test "refill renders the receive form" do
    get refill_inventory_restock_task_url(restock_tasks(:pending_auto))
    assert_response :success
  end

  test "complete creates an IN transaction and closes the task" do
    task = restock_tasks(:pending_auto)

    assert_difference -> { task.ingredient.stock_transactions.stock_in.count }, 1 do
      patch complete_inventory_restock_task_url(task),
            params: { restock_task: { received_quantity: 5, supplier: "ACME Foods", note: "Morning delivery" } }
    end

    task.reload
    assert task.completed?
    assert_equal 5.to_d, task.received_quantity
    assert_equal "ACME Foods", task.supplier
    assert_equal "Morning delivery", task.note
    assert_not_nil task.completed_at
    assert_redirected_to inventory_restock_task_url(task)
  end

  test "complete rejects a blank received quantity" do
    task = restock_tasks(:pending_auto)

    patch complete_inventory_restock_task_url(task), params: { restock_task: { received_quantity: "" } }

    assert_response :unprocessable_content
    assert_not task.reload.completed?
  end
end
