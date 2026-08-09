class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email, :string, default: "", null: false unless column_exists?(:users, :email)
    add_column :users, :encrypted_password, :string, default: "", null: false unless column_exists?(:users, :encrypted_password)
    add_column :users, :jti, :string, null: false, default: "" unless column_exists?(:users, :jti)

    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :jti, unique: true unless index_exists?(:users, :jti)
  end
end
