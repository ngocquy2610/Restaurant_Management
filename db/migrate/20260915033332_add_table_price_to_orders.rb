class AddTablePriceToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :table_price, :decimal, precision: 10, scale: 2
  end
end
