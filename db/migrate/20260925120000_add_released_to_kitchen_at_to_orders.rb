class AddReleasedToKitchenAtToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :released_to_kitchen_at, :datetime
    add_index :orders, [:status, :released_to_kitchen_at]
  end
end
