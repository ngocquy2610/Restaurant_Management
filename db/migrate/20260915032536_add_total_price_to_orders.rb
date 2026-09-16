class AddTotalPriceToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :total_price, :decimal, precision: 10, scale: 2
  end
end
