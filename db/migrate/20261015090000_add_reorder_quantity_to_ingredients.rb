class AddReorderQuantityToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :reorder_quantity, :decimal, precision: 12, scale: 3
  end
end
