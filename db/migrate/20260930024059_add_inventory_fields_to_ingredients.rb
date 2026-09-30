class AddInventoryFieldsToIngredients < ActiveRecord::Migration[8.1]
  def change
    rename_column :ingredients, :current_stock, :current_quantity
    add_column :ingredients, :category, :string, null: false, default: "other"
    add_column :ingredients, :status, :integer, null: false, default: 0

    add_index :ingredients, :category
    add_index :ingredients, :status
  end
end
