class MenusController < ApplicationController

  def index
    @categories = Category.all
    @foods = Food.all
    @food_variants = FoodVariant.all
    # Restaurant-wide reviews (one per customer) rendered as a guest review wall.
    @restaurant_reviews = Review.visible.recent.limit(3)
    @restaurant_review_count = Review.count
    @average_rating = Review.average_rating
  end

  def show
    @food = Food.find(params.expect(:id))
    @food_variants = @food.food_variants.order(:name)
    @recipe_items = @food.recipe_items.includes(:ingredient)
  end

end
