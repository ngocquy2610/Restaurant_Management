class AddRefillFieldsToRestockTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :restock_tasks, :received_quantity, :decimal, precision: 10, scale: 2
    add_column :restock_tasks, :supplier, :string
    add_column :restock_tasks, :note, :string
    add_column :restock_tasks, :completed_at, :datetime
  end
end
