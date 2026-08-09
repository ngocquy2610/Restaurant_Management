class ChangeJtiDefaultOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :jti, from: "", to: nil
  end
end
