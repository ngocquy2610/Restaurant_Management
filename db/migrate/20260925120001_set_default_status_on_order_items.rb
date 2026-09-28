class SetDefaultStatusOnOrderItems < ActiveRecord::Migration[8.1]
  def change
    change_column_default :order_items, :status, from: nil, to: 0
  end
end
