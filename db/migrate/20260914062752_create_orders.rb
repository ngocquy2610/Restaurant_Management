class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :table, null: false, foreign_key: true
      t.integer :status

      t.timestamps
    end
  end
end
