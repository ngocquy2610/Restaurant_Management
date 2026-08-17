class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string :name
      t.string :unit
      t.decimal :unit_cost, precision: 10, scale: 2
      t.decimal :current_stock, precision: 10, scale: 2
      t.decimal :low_stock_threshold, precision: 10, scale: 2

      t.timestamps
    end
    add_index :ingredients, :name, unique: true
  end
end
