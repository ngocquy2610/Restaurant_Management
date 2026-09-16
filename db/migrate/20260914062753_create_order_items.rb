class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :food, null: false, foreign_key: true
      t.references :food_variant, null: false, foreign_key: true
      t.integer :quantity
      t.text :special_note
      t.decimal :unit_price
      t.integer :status

      t.timestamps
    end
  end
end
