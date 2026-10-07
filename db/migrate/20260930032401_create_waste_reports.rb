class CreateWasteReports < ActiveRecord::Migration[8.1]
  def change
    create_table :waste_reports do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.references :user, foreign_key: true                    # người báo (kitchen)
      t.decimal :quantity,          precision: 10, scale: 2, null: false
      t.decimal :verified_quantity, precision: 10, scale: 2    # số thực tế quản lý kiểm được
      t.text    :reason
      t.integer :status, null: false, default: 0               # pending/approved/rejected
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :waste_reports, :status
    add_index :waste_reports, %i[ingredient_id created_at]
  end
end
