ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # A dish with a single-ingredient base recipe, isolated from fixtures.
    def build_dish(stock:, per_serving: 0.5, threshold: 0)
      tag  = SecureRandom.hex(3)
      food = Food.create!(category: Category.create!(name: "Cat #{tag}"), name: "Dish #{tag}", base_price: 10)
      ingredient = Ingredient.create!(name: "Ing #{tag}", unit: "kg", category: "other", unit_cost: 1,
                                      current_quantity: stock, low_stock_threshold: threshold)
      RecipeItem.create!(food: food, ingredient: ingredient, quantity_required: per_serving)
      [food, ingredient]
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
