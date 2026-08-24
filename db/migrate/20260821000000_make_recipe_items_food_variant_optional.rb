class MakeRecipeItemsFoodVariantOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :recipe_items, :food_variant_id, true
  end
end
