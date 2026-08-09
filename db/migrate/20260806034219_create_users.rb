class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :full_name, null: false
      t.string :phone, null: false
      t.string :email, null: false
      t.string :location
      t.integer :role, default: 0, null: false
      t.boolean :status, default: true, null: false
      t.string :avatar_url

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
