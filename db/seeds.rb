# This file should ensure the existence of records required to run the application in every
# environment (production, development, test). The code here should be idempotent so that it
# can be executed at any point in every environment.
#
# It seeds only Ingredient + RecipeItem records so that every existing Food has a recipe.
# Recipes are keyed by the dish name and linked to the Food records already in the database.

# =====================================================================
# Ingredient catalog
# name => [unit, unit_cost, current_stock, low_stock_threshold]
# =====================================================================
INGREDIENTS = {
  # ---- Meats & seafood -------------------------------------------------
  "Scallops"        => ["kg",     1.00, 12, 3],
  "Foie Gras"       => ["kg",     3.00,  2, 1],
  "Lobster"         => ["kg",     2.80,  4, 2],
  "Cod"             => ["kg",     1.00,  3, 1],
  "Salmon"          => ["kg",     1.40,  4, 1],
  "Duck Breast"     => ["kg",     1.20,  4, 1],
  "Pork Ribs"       => ["kg",     0.60,  3, 1],
  "Wagyu Beef"      => ["kg",     3.00,  1, 1],
  "Beef"            => ["kg",     0.80,  2, 1],
  "Lamb Chops"      => ["kg",     1.20,  2, 1],
  "Veal"            => ["kg",     1.20,  1, 1],
  "Octopus"         => ["kg",     1.00,  1, 1],
  "Prawns"          => ["kg",     1.60,  2, 1],
  "Shrimp"          => ["kg",     1.20,  2, 1],
  "Mussels"         => ["kg",     1.00,  1, 1],
  "King Crab"       => ["kg",     3.00,  1, 1],

  # ---- Dairy ---------------------------------------------------------------
  "Butter"          => ["kg",     0.40,  8, 2],
  "Cream"           => ["kg",     0.50,  1, 1],
  "Milk"            => ["kg",     0.40,  1, 1],
  "Coconut Milk"    => ["kg",     0.30,  1, 1],
  "Parmesan"        => ["kg",     1.60,  2, 1],
  "Mascarpone"      => ["kg",     0.90,  2, 1],
  "Gruyere"         => ["kg",     1.40,  2, 1],
  "Egg"             => ["piece",  0.20,  4, 1],

  # ---- Fruit & vegetables ---------------------------------------------------
  "Lemon"           => ["piece",  0.20,  4, 1],
  "Lime"            => ["piece",  0.20,  4, 1],
  "Orange"          => ["piece",  0.20,  6, 1],
  "Green Apple"     => ["piece",  0.20,  6, 1],
  "Apple"           => ["piece",  0.20,  4, 1],
  "Peach"           => ["piece",  0.30,  2, 1],
  "Tomato"          => ["piece",  0.15,  8, 2],
  "Pumpkin"         => ["kg",     0.30,  1, 1],
  "Onion"           => ["piece",  0.10,  3, 1],
  "Shallot"         => ["piece",  0.20,  2, 1],
  "Garlic"          => ["piece",  0.10,  3, 1],
  "Ginger"          => ["piece",  0.10,  2, 1],
  "Scallion"        => ["piece",  0.10,  3, 1],
  "Lemongrass"      => ["piece",  0.10,  1, 1],
  "Fennel"          => ["piece",  0.25,  1, 1],

  # ---- Fungi --------------------------------------------------------------
  "Mushroom"        => ["kg",     1.20,  3, 1],
  "Wild Mushroom"   => ["kg",     2.50,  1, 1],
  "Truffle"         => ["kg",    12.00,  1, 1],

  # ---- Grains, pantry & sweeteners -----------------------------------------
  "Flour"           => ["kg",     0.20,  3, 1],
  "Rice"            => ["kg",     0.40,  3, 1],
  "Arborio Rice"    => ["kg",     0.60,  1, 1],
  "Linguine"        => ["kg",     0.60,  2, 1],
  "Udon"            => ["kg",     0.50,  2, 1],
  "Baguette"        => ["kg",     0.50,  2, 1],
  "Breadcrumbs"     => ["kg",     0.40,  1, 1],
  "Ladyfinger Biscuits" => ["kg", 0.50,  1, 1],
  "Cocoa"           => ["kg",     0.60,  2, 1],
  "Chocolate"       => ["kg",     1.00,  2, 1],
  "Sugar"           => ["kg",     0.30,  6, 1],
  "Honey"           => ["kg",     0.80,  2, 1],
  "Vanilla"         => ["piece",  0.20,  2, 1],
  "Espresso"        => ["kg",     0.60,  1, 1],
  "Black Tea"       => ["g",      0.10,  1, 1],

  # ---- Oils, sauces & seasonings -------------------------------------------
  "Olive Oil"       => ["kg",     0.60,  3, 1],
  "Vegetable Oil"   => ["kg",     0.60,  2, 1],
  "Sesame Oil"      => ["kg",     1.00,  1, 1],
  "Red Wine"        => ["kg",     1.00,  2, 1],
  "White Wine"      => ["kg",     0.90,  2, 1],
  "Soy Sauce"       => ["kg",     0.50,  3, 1],
  "Salt"            => ["kg",     0.10,  5, 1],
  "Green Peppercorn" => ["g",     0.40,  1, 1],
  "Saffron"         => ["g",      1.00,  1, 1],
  "Smoked Paprika"  => ["g",      0.10,  1, 1],
  "Miso Paste"      => ["kg",     1.00,  1, 1],
  "Curry Paste"     => ["kg",     1.00,  1, 1],
  "Seaweed"         => ["kg",     1.00,  1, 1],
  "Tofu"            => ["kg",     0.80,  1, 1],
  "Vegetable Stock" => ["kg",     0.40,  2, 1],
  "Beef Broth"      => ["kg",     0.40,  2, 1],
  "Fish Stock"      => ["kg",     0.40,  2, 1],
  "Dashi"           => ["kg",     0.50,  1, 1],

  # ---- Fresh herbs --------------------------------------------
  "Parsley"         => ["g",      0.10,  2, 1],
  "Dill"            => ["g",      0.10,  2, 1],
  "Cilantro"        => ["g",      0.10,  2, 1],
  "Thyme"           => ["g",      0.10,  2, 1],
  "Rosemary"        => ["g",      0.10,  2, 1],
  "Mint"            => ["g",      0.10,  2, 1]
}
# =====================================================================
# Recipes keyed by dish name. Each entry: [ingredient_name, quantity]
# =====================================================================
RECIPES = {
  "Pan-Seared Scallops with Lemon Butter Sauce" => [
    ["Scallops", 0.20], ["Butter", 0.02], ["Lemon", 0.50], ["Garlic", 1.0], ["Parsley", 1.0]
  ],
  "Pan-Seared Foie Gras with Apple Sauce" => [
    ["Foie Gras", 0.10], ["Apple", 0.50], ["Butter", 0.02], ["Sugar", 0.01], ["Cream", 0.02]
  ],
  "Grilled Wagyu Beef with Green Peppercorn Sauce" => [
    ["Wagyu Beef", 0.20], ["Green Peppercorn", 1.0], ["Butter", 0.02], ["Cream", 0.02]
  ],
  "Japanese-Style Steamed Cod" => [
    ["Cod", 0.20], ["Soy Sauce", 0.02], ["Ginger", 0.10], ["Scallion", 0.10], ["Dashi", 0.02]
  ],
  "Peking Roast Duck" => [
    ["Duck Breast", 0.20], ["Honey", 0.01], ["Soy Sauce", 0.01], ["Ginger", 0.10], ["Sesame Oil", 0.01]
  ],
  "Miso-Glazed Seared Salmon" => [
    ["Salmon", 0.15], ["Miso Paste", 0.02], ["Sugar", 0.01], ["Sesame Oil", 0.005]
  ],
  "Honey-Glazed Grilled Pork Ribs" => [
    ["Pork Ribs", 0.20], ["Honey", 0.01], ["Soy Sauce", 0.02], ["Garlic", 1.0], ["Cilantro", 1.0]
  ],
  "Tiger Prawns with Garlic Butter" => [
    ["Prawns", 0.20], ["Butter", 0.02], ["Garlic", 1.0], ["Parsley", 1.0], ["Lemon", 0.50]
  ],
  "Vietnamese Shaking Beef" => [
    ["Beef", 0.20], ["Lemongrass", 0.10], ["Soy Sauce", 0.01], ["Green Peppercorn", 1.0], ["Mint", 1.0]
  ],
  "Royal Seafood Fried Rice" => [
    ["Rice", 0.10], ["Shrimp", 0.05], ["Scallops", 0.05], ["Mussels", 0.05], ["Egg", 1.0], ["Scallion", 0.10], ["Sesame Oil", 0.01]
  ],
  "Wagyu Beef Udon" => [
    ["Udon", 0.10], ["Wagyu Beef", 0.10], ["Dashi", 0.02], ["Scallion", 0.10], ["Soy Sauce", 0.01]
  ],
  "Thai-Style Prawn Curry" => [
    ["Prawns", 0.15], ["Curry Paste", 0.02], ["Coconut Milk", 0.02], ["Lime", 0.10], ["Cilantro", 1.0]
  ],
  "Creamy Pumpkin Soup" => [
    ["Pumpkin", 0.20], ["Onion", 0.50], ["Milk", 0.10], ["Butter", 0.02], ["Vegetable Stock", 0.02]
  ],
  "Truffle Mushroom Soup" => [
    ["Mushroom", 0.15], ["Truffle", 0.01], ["Cream", 0.02], ["Onion", 0.50], ["Butter", 0.02]
  ],
  "Japanese Seafood Soup" => [
    ["Shrimp", 0.10], ["Scallops", 0.10], ["Seaweed", 0.01], ["Tofu", 0.01], ["Dashi", 0.02]
  ],
  "French Onion Soup" => [
    ["Onion", 2.00], ["Beef Broth", 0.30], ["Butter", 0.02], ["Baguette", 0.01], ["Gruyere", 0.01]
  ],
  "Classic Lobster Bisque" => [
    ["Lobster", 0.20], ["Shrimp", 0.10], ["Cream", 0.02], ["Tomato", 0.10], ["Butter", 0.02], ["Fish Stock", 0.30]
  ],
  "Pan-Seared Duck Breast with Orange Sauce" => [
    ["Duck Breast", 0.20], ["Orange", 0.50], ["Sugar", 0.02], ["Butter", 0.02]
  ],
  "Grilled Salmon with Lemon Butter Sauce" => [
    ["Salmon", 0.15], ["Butter", 0.02], ["Lemon", 0.50], ["Garlic", 1.0], ["Dill", 1.0]
  ],
  "Lobster Linguine" => [
    ["Lobster", 0.20], ["Linguine", 0.06], ["Tomato", 0.10], ["Garlic", 1.0], ["Cream", 0.02], ["Parsley", 1.0]
  ],
  "Truffle Mushroom Risotto" => [
    ["Arborio Rice", 0.06], ["Truffle", 0.01], ["Mushroom", 0.05], ["Parmesan", 0.01], ["Butter", 0.02], ["White Wine", 0.02]
  ],
  "Herb-Crusted Lamb Chops" => [
    ["Lamb Chops", 0.20], ["Garlic", 1.0], ["Rosemary", 1.0], ["Thyme", 1.0], ["Breadcrumbs", 0.01], ["Parmesan", 0.01]
  ],
  "Roasted Cod with Saffron Sauce" => [
    ["Cod", 0.20], ["Saffron", 0.01], ["Fish Stock", 0.30], ["Cream", 0.02], ["Fennel", 0.10], ["Butter", 0.02]
  ],
  "Veal Tenderloin with Wild Mushroom Sauce" => [
    ["Veal", 0.20], ["Wild Mushroom", 0.05], ["Cream", 0.02], ["Shallot", 0.10], ["Butter", 0.02], ["Red Wine", 0.02]
  ],
  "Grilled Lobster with Garlic Butter" => [
    ["Lobster", 0.20], ["Garlic", 1.0], ["Butter", 0.02], ["Lemon", 0.50], ["Parsley", 1.0]
  ],
  "Seared Scallops with Saffron Sauce" => [
    ["Scallops", 0.20], ["Saffron", 0.01], ["Cream", 0.02], ["Shallot", 0.10], ["Fennel", 0.10]
  ],
  "Mediterranean Grilled Octopus" => [
    ["Octopus", 0.20], ["Olive Oil", 0.02], ["Garlic", 1.0], ["Red Wine", 0.02], ["Lemon", 0.50], ["Smoked Paprika", 1.0]
  ],
  "King Crab with Lemon Butter Sauce" => [
    ["King Crab", 0.20], ["Butter", 0.02], ["Lemon", 0.50], ["Garlic", 1.0], ["Parsley", 1.0]
  ],
  "Fresh Orange Juice" => [
    ["Orange", 2.00], ["Sugar", 0.01]
  ],
  "Fresh Green Apple Juice" => [
    ["Green Apple", 2.00], ["Lemon", 0.05]
  ],
  "Peach, Orange & Lemongrass Tea" => [
    ["Peach", 0.50], ["Orange", 0.50], ["Lemongrass", 0.05], ["Black Tea", 0.01], ["Honey", 0.01]
  ],
  "Classic Vanilla Crème Brûlée" => [
    ["Cream", 0.10], ["Egg", 2.00], ["Sugar", 0.02], ["Vanilla", 0.50]
  ],
  "Chocolate Fondant" => [
    ["Chocolate", 0.03], ["Flour", 0.02], ["Egg", 1.00], ["Butter", 0.02], ["Sugar", 0.01]
  ],
  "Classic Italian Tiramisu" => [
    ["Mascarpone", 0.06], ["Espresso", 0.02], ["Ladyfinger Biscuits", 0.01], ["Cocoa", 0.005], ["Sugar", 0.01], ["Egg", 1.00]
  ]
}

# =====================================================================
# Seed ingredients + recipe items for every existing food
# =====================================================================
recipes = RECIPES

# Look up foods already present in the database by name.
foods_by_name = Food.all.each_with_object({}) { |food, hash| hash[food.name] = food }

seeded_foods = []

recipes.each do |food_name, ingredients|
  food = foods_by_name[food_name]

  if food.nil?
    puts "WARNING: Food '#{food_name}' not found in the database - skipping its recipe."
    next
  end

  ingredients.each do |(ingredient_name, quantity)|
    attrs = INGREDIENTS.fetch(ingredient_name)

    ingredient = Ingredient.find_or_create_by!(name: ingredient_name) do |i|
      i.unit = attrs[0]
      i.unit_cost = attrs[1]
      i.current_stock = attrs[2]
      i.low_stock_threshold = attrs[3]
    end

    RecipeItem.find_or_create_by!(
      food_id: food.id,
      food_variant_id: nil,
      ingredient_id: ingredient.id
    ) do |ri|
      ri.quantity_required = quantity
    end

    puts "RecipeItem: #{food.name} <- #{ingredient_name} (#{quantity} #{ingredient.unit})"
  end

  seeded_foods << food.name
end

# Report any existing foods that were not given a recipe, so coverage is obvious.
uncovered = Food.where.not(name: seeded_foods).pluck(:name)
unless uncovered.empty?
  puts "WARNING: No recipe defined for these existing foods: #{uncovered.join(', ')}"
end

puts "Seeding complete."