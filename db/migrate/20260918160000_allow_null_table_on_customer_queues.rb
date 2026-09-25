class AllowNullTableOnCustomerQueues < ActiveRecord::Migration[8.1]
  def change
    # A walk-in guest joins the waiting queue *before* a table is assigned,
    # so `table_id` must be nullable until the guest is seated.
    change_column_null :customer_queues, :table_id, true
  end
end
