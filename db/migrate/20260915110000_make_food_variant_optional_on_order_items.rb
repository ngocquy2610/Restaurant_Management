class MakeFoodVariantOptionalOnOrderItems < ActiveRecord::Migration[8.1]
  def change
    change_column_null :order_items, :food_variant_id, true
  end
end