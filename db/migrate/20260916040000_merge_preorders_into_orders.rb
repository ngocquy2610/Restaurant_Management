class MergePreordersIntoOrders < ActiveRecord::Migration[8.1]
  def change
    # link a pre-order directly to its reservation (replaces the old preorders
    # join table's reservation_id column).
    add_reference :orders, :reservation, null: true, foreign_key: true

    drop_table :preorders, if_exists: true
  end
end