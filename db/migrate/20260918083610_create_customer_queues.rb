class CreateCustomerQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_queues do |t|
      t.string  :guest_name,  null: false
      t.string  :guest_phone, null: false
      t.integer :status,      null: false, default: 0
      t.bigint  :user_id,     null: false
      t.bigint  :table_id
      t.string  :note

      t.timestamps
    end
    add_index :customer_queues, [ :status, :created_at ]
    add_index :customer_queues, :guest_phone
    add_foreign_key :customer_queues, :users
    add_foreign_key :customer_queues, :tables
  end
end
