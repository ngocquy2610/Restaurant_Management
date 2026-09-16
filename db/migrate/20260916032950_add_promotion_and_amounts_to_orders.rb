class AddPromotionAndAmountsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :promotion_id, :bigint
    add_column :orders, :subtotal, :decimal
    add_column :orders, :discount_amount, :decimal
  end
end
