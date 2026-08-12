class CreateAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :areas do |t|
      t.string :name
      t.integer :area_type
      t.integer :floor_level

      t.timestamps
    end
  end
end
