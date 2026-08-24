class CreateMemberTiers < ActiveRecord::Migration[8.1]
  def change
    create_table :member_tiers do |t|
      t.string :name
      t.integer :discount
      t.integer :active_price

      t.timestamps
    end
  end
end
