class CreateLowStockRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :low_stock_requests do |t|
      t.references :user,       null: false, foreign_key: true   # kitchen user gửi yêu cầu
      t.references :ingredient, null: false, foreign_key: true
      t.text    :note
      t.integer :status, null: false, default: 0                 # pending/approved/rejected/completed
      # ⚠️ Tên cột `reviewed_by_id` không khớp bảng `users` → phải chỉ rõ to_table
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :low_stock_requests, :status
    add_index :low_stock_requests, %i[ingredient_id status]
  end
end
