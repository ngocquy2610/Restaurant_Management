class AddActiveToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :active, :boolean, null: false, default: true
    add_index  :ingredients, :active
  end
end
