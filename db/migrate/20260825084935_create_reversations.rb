class CreateReversations < ActiveRecord::Migration[8.1]
  def change
    create_table :reversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :guest_name
      t.string :guest_phone
      t.references :table, null: false, foreign_key: true
      t.integer :status
      t.string :note

      t.timestamps
    end
  end
end
