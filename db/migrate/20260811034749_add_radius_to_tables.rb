class AddRadiusToTables < ActiveRecord::Migration[8.1]
  def change
    add_column :tables, :radius, :decimal, precision: 8, scale: 2, default: nil
  end
end
