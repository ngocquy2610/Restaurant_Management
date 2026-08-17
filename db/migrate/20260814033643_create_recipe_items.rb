class CreateRecipeItems < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_items do |t|
      t.references :food, null: false, foreign_key: true
      t.references :food_variant, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity_required, precision: 10, scale: 2

      t.timestamps
    end
  end
end
