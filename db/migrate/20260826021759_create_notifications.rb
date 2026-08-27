class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.string :body
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :notifications, [:recipient_id, :status]
  end
end
