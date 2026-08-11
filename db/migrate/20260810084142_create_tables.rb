class CreateTables < ActiveRecord::Migration[8.1]
  def change
    create_table :tables do |t|
      t.references :table_type, null: false, foreign_key: true
      t.integer :capacity
      t.integer :status

      t.timestamps
    end
  end
end
