class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.references :payment_method, null: false, foreign_key: true
      t.references :processed_by, null: true, foreign_key: { to_table: :users }
      t.decimal :subtotal
      t.decimal :discount_amount
      t.decimal :total_amount
      t.integer :status
      t.text :qr_code_data
      t.text :failure_reason
      t.string :currency
      t.string :idempotency_key
      t.datetime :paid_at
      t.datetime :refunded_at

      t.timestamps
    end
  end
end
