class AddRedirectUrlToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :redirect_url, :string
  end
end
