class CreateFoodVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :food_variants do |t|
      t.references :food, null: false, foreign_key: true
      t.string :name
      t.decimal :price_adjustment, precision: 10, scale: 2

      t.timestamps
    end
  end
end
