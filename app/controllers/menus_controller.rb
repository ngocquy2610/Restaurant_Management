class MenusController < ApplicationController

  def index
    @categories = Category.all
    @foods = Food.all
    @food_variants = FoodVariant.all
  end

  def show
    @food = Food.find(params.expect(:id))
    @food_variants = @food.food_variants.order(:name)
    @recipe_items = @food.recipe_items.includes(:ingredient)
  end

end
