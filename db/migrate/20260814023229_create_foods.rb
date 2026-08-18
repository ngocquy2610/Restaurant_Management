class CreateFoods < ActiveRecord::Migration[8.1]
  def change
    create_table :foods do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :base_price, precision: 10, scale: 2
      t.integer :status

      t.timestamps
    end
  end
end
