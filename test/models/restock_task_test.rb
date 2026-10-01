require "test_helper"

class RestockTaskTest < ActiveSupport::TestCase
  test "source request requires a request reference" do
    task = RestockTask.new(ingredient: ingredients(:one), quantity: 5, source: :request)
    assert_not task.valid?
    assert_includes task.errors[:low_stock_request], "is required when source is request"
  end

  test "source waste requires a waste reference" do
    task = RestockTask.new(ingredient: ingredients(:one), quantity: 5, source: :waste)
    assert_not task.valid?
    assert_includes task.errors[:waste_report], "is required when source is waste"
  end

  test "auto source needs no reference" do
    task = RestockTask.new(ingredient: ingredients(:one), quantity: 5, source: :auto)
    assert task.valid?, task.errors.full_messages.join(", ")
  end

  test "open scope covers only pending and in_progress" do
    assert_includes RestockTask.open, restock_tasks(:pending_auto)
    assert_includes RestockTask.open, restock_tasks(:in_progress_request)

    restock_tasks(:pending_auto).update!(status: :completed)
    assert_not_includes RestockTask.open, restock_tasks(:pending_auto)
  end

  test "complete! flips status to completed" do
    task = restock_tasks(:pending_auto)
    task.complete!
    assert task.reload.completed?
  end
end
