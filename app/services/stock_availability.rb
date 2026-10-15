module StockAvailability
  Shortage = Struct.new(:ingredient, :needed, :available, keyword_init: true) do
    def message
      "#{ingredient.name}: need #{needed.to_f} #{ingredient.unit}, only #{[available, 0].max.to_f} left"
    end
  end

  class << self
    def shortages(food_id:, variant_id: nil, quantity: 1)
      RecipeItem.for_item(food_id: food_id, variant_id: variant_id).filter_map do |ri|
        ing = ri.ingredient
        next if ing.nil?
        needed    = ri.quantity_required.to_d * quantity.to_i
        available = ing.active? ? ing.current_quantity.to_d : 0.to_d
        Shortage.new(ingredient: ing, needed: needed, available: available) if needed > available
      end
    end

    def unavailable_food_ids
      RecipeItem.where(food_variant_id: nil).joins(:ingredient)
                .where("ingredients.active = FALSE OR ingredients.current_quantity < recipe_items.quantity_required")
                .distinct.pluck(:food_id)
    end
  end
end