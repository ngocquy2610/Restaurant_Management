class CreateStockTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_transactions do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :transaction_type, null: false, default: 0
      t.decimal :quantity,        precision: 10, scale: 2, null: false
      t.decimal :quantity_before, precision: 10, scale: 2
      t.decimal :quantity_after,  precision: 10, scale: 2
      t.string  :reason
      t.string  :reference, limit: 80
      t.timestamps
    end

    add_index :stock_transactions, :transaction_type
    add_index :stock_transactions, %i[ingredient_id created_at]
  end
end
