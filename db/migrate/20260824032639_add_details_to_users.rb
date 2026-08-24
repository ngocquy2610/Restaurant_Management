class AddDetailsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :member_tier, null: true, foreign_key: true
    add_column :users, :year_spend, :decimal, precision: 10, scale: 2
  end
end
