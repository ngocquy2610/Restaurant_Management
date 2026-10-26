class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_hash, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.string :device_name, null: false, default: ""
      t.string :user_agent, null: false, default: ""

      t.timestamps null: false
    end

    add_index :refresh_tokens, :token_hash, unique: true
    add_index :refresh_tokens, [:user_id, :expires_at]
  end
end
