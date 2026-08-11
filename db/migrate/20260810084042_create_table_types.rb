class CreateTableTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :table_types do |t|
      t.string :type
      t.decimal :price_add_on, precision: 10, scale: 2

      t.timestamps
    end
  end
end
