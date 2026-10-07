class CreateRestockTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :restock_tasks do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.integer :status, null: false, default: 0     # pending/in_progress/completed/cancelled
      t.integer :source, null: false, default: 0     # auto/request/waste
      t.references :low_stock_request   # nguồn gốc khi source = request
      t.references :waste_report   # nguồn gốc khi source = waste
      t.datetime :due_on
      t.timestamps
    end

    add_index :restock_tasks, :status
    add_index :restock_tasks, :source
  end
end
