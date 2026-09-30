class AddForeignKeysToRestockTasks < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :restock_tasks, :low_stock_requests
    add_foreign_key :restock_tasks, :waste_reports
  end
end
