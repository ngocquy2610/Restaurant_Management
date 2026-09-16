class AddPaymentIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :payment_methods, :code, unique: true
    add_index :payments, :idempotency_key, unique: true
    add_foreign_key :orders, :promotions 
  end
end
