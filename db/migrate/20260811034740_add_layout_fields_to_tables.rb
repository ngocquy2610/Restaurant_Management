class AddLayoutFieldsToTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :tables, :area, null: false, foreign_key: true
    add_column :tables, :table_number, :string
    add_column :tables, :shape, :integer
    add_column :tables, :pos_x, :decimal, precision: 8, scale: 2
    add_column :tables, :pos_y, :decimal, precision: 8, scale: 2
    add_column :tables, :width, :decimal, precision: 8, scale: 2, default: nil
    add_column :tables, :height, :decimal, precision: 8, scale: 2, default: nil
    add_column :tables, :rotation, :integer, default: nil
  end
end
