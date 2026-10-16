# frozen_string_literal: true

puts "== Restaurant seed: base app data =="

# ---------------------------------------------------------------------------
# Helpers (đặt ngoài transaction cho gọn)
# ---------------------------------------------------------------------------

# Mật khẩu cho các tài khoản demo. Trên server NÊN đặt SEED_PASSWORD trong file env
# để không ai đoán được mật khẩu admin.
def default_password
  ENV.fetch("SEED_PASSWORD", "Password123!")
end

if Rails.env.production? && ENV["SEED_PASSWORD"].blank?
  puts "WARNING: SEED_PASSWORD is not set. Demo accounts will use the public default password!"
end

def create_user(email:, full_name:, phone:, role:, year_spend: 0)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(
    full_name: full_name,
    phone: phone,
    password: default_password,
    role: role,
    status: true,
    year_spend: year_spend.to_d
  )
  user.save!
  user
end

# Tồn kho ban đầu = số lượng gốc x STOCK_BOOST.
# Lỗi cũ "Green Peppercorn: need 2.0 g, only 1.0 left" xảy ra vì tồn kho quá nhỏ
# so với số lượng món trong đơn mẫu.
STOCK_BOOST = 20

# [tên, đơn vị, giá vốn, tồn kho gốc, ngưỡng cảnh báo, nhóm]
INGREDIENT_SPECS = [
  ["Scallops", "kg", 1.00, 12, 3, "seafood"],
  ["Foie Gras", "kg", 3.00, 2, 1, "meat"],
  ["Lobster", "kg", 2.80, 4, 2, "seafood"],
  ["Cod", "kg", 1.00, 3, 1, "seafood"],
  ["Salmon", "kg", 1.40, 4, 1, "seafood"],
  ["Duck Breast", "kg", 1.20, 4, 1, "meat"],
  ["Pork Ribs", "kg", 0.60, 3, 1, "meat"],
  ["Wagyu Beef", "kg", 3.00, 2, 1, "meat"],
  ["Beef", "kg", 0.80, 2, 1, "meat"],
  ["Lamb Chops", "kg", 1.20, 2, 1, "meat"],
  ["Veal", "kg", 1.20, 1, 1, "meat"],
  ["Octopus", "kg", 1.00, 1, 1, "seafood"],
  ["Prawns", "kg", 1.60, 2, 1, "seafood"],
  ["Shrimp", "kg", 1.20, 2, 1, "seafood"],
  ["Mussels", "kg", 1.00, 1, 1, "seafood"],
  ["King Crab", "kg", 3.00, 1, 1, "seafood"],
  ["Butter", "kg", 0.40, 8, 2, "dairy"],
  ["Cream", "kg", 0.50, 1, 1, "dairy"],
  ["Milk", "kg", 0.40, 1, 1, "dairy"],
  ["Coconut Milk", "kg", 0.30, 1, 1, "dairy"],
  ["Parmesan", "kg", 1.60, 2, 1, "dairy"],
  ["Mascarpone", "kg", 0.90, 2, 1, "dairy"],
  ["Gruyere", "kg", 1.40, 2, 1, "dairy"],
  ["Egg", "piece", 0.20, 4, 1, "dairy"],
  ["Lemon", "piece", 0.20, 4, 1, "produce"],
  ["Lime", "piece", 0.20, 4, 1, "produce"],
  ["Orange", "piece", 0.20, 6, 1, "produce"],
  ["Green Apple", "piece", 0.20, 6, 1, "produce"],
  ["Apple", "piece", 0.20, 4, 1, "produce"],
  ["Peach", "piece", 0.30, 2, 1, "produce"],
  ["Tomato", "piece", 0.15, 8, 2, "produce"],
  ["Pumpkin", "kg", 0.30, 1, 1, "produce"],
  ["Onion", "piece", 0.10, 3, 1, "produce"],
  ["Shallot", "piece", 0.20, 2, 1, "produce"],
  ["Garlic", "piece", 0.10, 3, 1, "produce"],
  ["Ginger", "piece", 0.10, 2, 1, "produce"],
  ["Scallion", "piece", 0.10, 3, 1, "produce"],
  ["Lemongrass", "piece", 0.10, 1, 1, "produce"],
  ["Fennel", "piece", 0.25, 1, 1, "produce"],
  ["Mushroom", "kg", 1.20, 3, 1, "produce"],
  ["Wild Mushroom", "kg", 2.50, 1, 1, "produce"],
  ["Truffle", "kg", 12.00, 1, 1, "produce"],
  ["Flour", "kg", 0.20, 3, 1, "dry"],
  ["Rice", "kg", 0.40, 3, 1, "dry"],
  ["Arborio Rice", "kg", 0.60, 1, 1, "dry"],
  ["Linguine", "kg", 0.60, 2, 1, "dry"],
  ["Udon", "kg", 0.50, 2, 1, "dry"],
  ["Baguette", "kg", 0.50, 2, 1, "bakery"],
  ["Breadcrumbs", "kg", 0.40, 1, 1, "dry"],
  ["Ladyfinger Biscuits", "kg", 0.50, 1, 1, "bakery"],
  ["Cocoa", "kg", 0.60, 2, 1, "dry"],
  ["Chocolate", "kg", 1.00, 2, 1, "dry"],
  ["Sugar", "kg", 0.30, 6, 1, "dry"],
  ["Honey", "kg", 0.80, 2, 1, "dry"],
  ["Vanilla", "piece", 0.20, 2, 1, "beverage"],
  ["Espresso", "kg", 0.60, 1, 1, "beverage"],
  ["Black Tea", "g", 0.10, 1, 1, "dry"],
  ["Olive Oil", "kg", 0.60, 3, 1, "beverage"],
  ["Vegetable Oil", "kg", 0.60, 2, 1, "beverage"],
  ["Sesame Oil", "kg", 1.00, 1, 1, "beverage"],
  ["Red Wine", "kg", 1.00, 2, 1, "beverage"],
  ["White Wine", "kg", 0.90, 2, 1, "beverage"],
  ["Soy Sauce", "kg", 0.50, 3, 1, "dry"],
  ["Salt", "kg", 0.10, 5, 1, "dry"],
  ["Green Peppercorn", "g", 0.40, 2, 1, "dry"],
  ["Saffron", "g", 1.00, 1, 1, "dry"],
  ["Smoked Paprika", "g", 0.10, 1, 1, "dry"],
  ["Miso Paste", "kg", 1.00, 1, 1, "dry"],
  ["Curry Paste", "kg", 1.00, 1, 1, "dry"],
  ["Seaweed", "kg", 1.00, 1, 1, "dry"],
  ["Tofu", "kg", 0.80, 1, 1, "other"],
  ["Vegetable Stock", "kg", 0.40, 2, 1, "dry"],
  ["Beef Broth", "kg", 0.40, 2, 1, "dry"],
  ["Fish Stock", "kg", 0.40, 2, 1, "dry"],
  ["Dashi", "kg", 0.50, 1, 1, "dry"],
  ["Parsley", "g", 0.10, 2, 1, "produce"],
  ["Dill", "g", 0.10, 2, 1, "produce"],
  ["Cilantro", "g", 0.10, 2, 1, "produce"],
  ["Thyme", "g", 0.10, 2, 1, "produce"],
  ["Rosemary", "g", 0.10, 2, 1, "produce"],
  ["Mint", "g", 0.10, 2, 1, "produce"]
].freeze

RECIPE_SPECS = {
  "Pan-Seared Scallops with Lemon Butter Sauce" => [["Scallops", 0.20], ["Butter", 0.02], ["Lemon", 0.50], ["Garlic", 1.0], ["Parsley", 1.0]],
  "Pan-Seared Foie Gras with Apple Sauce" => [["Foie Gras", 0.10], ["Apple", 0.50], ["Butter", 0.02], ["Sugar", 0.01], ["Cream", 0.02]],
  "Grilled Wagyu Beef with Green Peppercorn Sauce" => [["Wagyu Beef", 0.20], ["Green Peppercorn", 1.0], ["Butter", 0.02], ["Cream", 0.02]],
  "Japanese-Style Steamed Cod" => [["Cod", 0.20], ["Soy Sauce", 0.02], ["Ginger", 0.10], ["Scallion", 0.10], ["Dashi", 0.02]],
  "Peking Roast Duck" => [["Duck Breast", 0.20], ["Honey", 0.01], ["Soy Sauce", 0.01], ["Ginger", 0.10], ["Sesame Oil", 0.01]],
  "Miso-Glazed Seared Salmon" => [["Salmon", 0.15], ["Miso Paste", 0.02], ["Sugar", 0.01], ["Sesame Oil", 0.005]],
  "Honey-Glazed Grilled Pork Ribs" => [["Pork Ribs", 0.20], ["Honey", 0.01], ["Soy Sauce", 0.02], ["Garlic", 1.0], ["Cilantro", 1.0]],
  "Tiger Prawns with Garlic Butter" => [["Prawns", 0.20], ["Butter", 0.02], ["Garlic", 1.0], ["Parsley", 1.0], ["Lemon", 0.50]],
  "Vietnamese Shaking Beef" => [["Beef", 0.20], ["Lemongrass", 0.10], ["Soy Sauce", 0.01], ["Green Peppercorn", 1.0], ["Mint", 1.0]],
  "Royal Seafood Fried Rice" => [["Rice", 0.10], ["Shrimp", 0.05], ["Scallops", 0.05], ["Mussels", 0.05], ["Egg", 1.0], ["Scallion", 0.10], ["Sesame Oil", 0.01]],
  "Wagyu Beef Udon" => [["Udon", 0.10], ["Wagyu Beef", 0.10], ["Dashi", 0.02], ["Scallion", 0.10], ["Soy Sauce", 0.01]],
  "Thai-Style Prawn Curry" => [["Prawns", 0.15], ["Curry Paste", 0.02], ["Coconut Milk", 0.02], ["Lime", 0.10], ["Cilantro", 1.0]],
  "Creamy Pumpkin Soup" => [["Pumpkin", 0.20], ["Onion", 0.50], ["Milk", 0.10], ["Butter", 0.02], ["Vegetable Stock", 0.02]],
  "Truffle Mushroom Soup" => [["Mushroom", 0.15], ["Truffle", 0.01], ["Cream", 0.02], ["Onion", 0.50], ["Butter", 0.02]],
  "Japanese Seafood Soup" => [["Shrimp", 0.10], ["Scallops", 0.10], ["Seaweed", 0.01], ["Tofu", 0.01], ["Dashi", 0.02]],
  "French Onion Soup" => [["Onion", 2.00], ["Beef Broth", 0.30], ["Butter", 0.02], ["Baguette", 0.01], ["Gruyere", 0.01]],
  "Classic Lobster Bisque" => [["Lobster", 0.20], ["Shrimp", 0.10], ["Cream", 0.02], ["Tomato", 0.10], ["Butter", 0.02], ["Fish Stock", 0.30]],
  "Pan-Seared Duck Breast with Orange Sauce" => [["Duck Breast", 0.20], ["Orange", 0.50], ["Sugar", 0.02], ["Butter", 0.02]],
  "Grilled Salmon with Lemon Butter Sauce" => [["Salmon", 0.15], ["Butter", 0.02], ["Lemon", 0.50], ["Garlic", 1.0], ["Dill", 1.0]],
  "Lobster Linguine" => [["Lobster", 0.20], ["Linguine", 0.06], ["Tomato", 0.10], ["Garlic", 1.0], ["Cream", 0.02], ["Parsley", 1.0]],
  "Truffle Mushroom Risotto" => [["Arborio Rice", 0.06], ["Truffle", 0.01], ["Mushroom", 0.05], ["Parmesan", 0.01], ["Butter", 0.02], ["White Wine", 0.02]],
  "Herb-Crusted Lamb Chops" => [["Lamb Chops", 0.20], ["Garlic", 1.0], ["Rosemary", 1.0], ["Thyme", 1.0], ["Breadcrumbs", 0.01], ["Parmesan", 0.01]],
  "Roasted Cod with Saffron Sauce" => [["Cod", 0.20], ["Saffron", 0.01], ["Fish Stock", 0.30], ["Cream", 0.02], ["Fennel", 0.10], ["Butter", 0.02]],
  "Veal Tenderloin with Wild Mushroom Sauce" => [["Veal", 0.20], ["Wild Mushroom", 0.05], ["Cream", 0.02], ["Shallot", 0.10], ["Butter", 0.02], ["Red Wine", 0.02]],
  "Grilled Lobster with Garlic Butter" => [["Lobster", 0.20], ["Garlic", 1.0], ["Butter", 0.02], ["Lemon", 0.50], ["Parsley", 1.0]],
  "Seared Scallops with Saffron Sauce" => [["Scallops", 0.20], ["Saffron", 0.01], ["Cream", 0.02], ["Shallot", 0.10], ["Fennel", 0.10]],
  "Mediterranean Grilled Octopus" => [["Octopus", 0.20], ["Olive Oil", 0.02], ["Garlic", 1.0], ["Red Wine", 0.02], ["Lemon", 0.50], ["Smoked Paprika", 1.0]],
  "King Crab with Lemon Butter Sauce" => [["King Crab", 0.20], ["Butter", 0.02], ["Lemon", 0.50], ["Garlic", 1.0], ["Parsley", 1.0]],
  "Fresh Orange Juice" => [["Orange", 2.00], ["Sugar", 0.01]],
  "Fresh Green Apple Juice" => [["Green Apple", 2.00], ["Lemon", 0.05]],
  "Peach, Orange & Lemongrass Tea" => [["Peach", 0.50], ["Orange", 0.50], ["Lemongrass", 0.05], ["Black Tea", 0.01], ["Honey", 0.01]],
  "Classic Vanilla Crème Brûlée" => [["Cream", 0.10], ["Egg", 2.00], ["Sugar", 0.02], ["Vanilla", 0.50]],
  "Chocolate Fondant" => [["Chocolate", 0.03], ["Flour", 0.02], ["Egg", 1.00], ["Butter", 0.02], ["Sugar", 0.01]],
  "Classic Italian Tiramisu" => [["Mascarpone", 0.06], ["Espresso", 0.02], ["Ladyfinger Biscuits", 0.01], ["Cocoa", 0.005], ["Sugar", 0.01], ["Egg", 1.00]]
}.freeze

# ---------------------------------------------------------------------------
# Seed
# ---------------------------------------------------------------------------

ApplicationRecord.transaction do
  # --- Member tiers ---------------------------------------------------------
  member_tiers = {
    "Bronze" => { active_price: 0, discount: 5 },
    "Silver" => { active_price: 2000, discount: 10 },
    "Gold" => { active_price: 5000, discount: 15 },
    "Platinum" => { active_price: 10000, discount: 20 }
  }

  member_tiers.each do |name, attrs|
    MemberTier.find_or_create_by!(name: name) do |tier|
      tier.active_price = attrs[:active_price]
      tier.discount = attrs[:discount]
    end
  end

  # --- Users ----------------------------------------------------------------
  admin = create_user(email: "admin@restaurant.test", full_name: "Restaurant Admin", phone: "0900000000", role: :admin, year_spend: 15000)
  create_user(email: "inventory@restaurant.test", full_name: "Inventory Manager", phone: "0900000001", role: :inventory_manager, year_spend: 5000)
  kitchen_staff = create_user(email: "kitchen@restaurant.test", full_name: "Kitchen Lead", phone: "0900000002", role: :kitchen_staff, year_spend: 1200)
  create_user(email: "reception@restaurant.test", full_name: "Reception Desk", phone: "0900000003", role: :receptionist, year_spend: 800)
  waiter = create_user(email: "waiter@restaurant.test", full_name: "Waiter Alex", phone: "0900000004", role: :waiter, year_spend: 1600)
  customer = create_user(email: "customer@restaurant.test", full_name: "Alicia Nguyen", phone: "0900000005", role: :customer, year_spend: 3500)

  # --- Areas ----------------------------------------------------------------
  area_map = {}
  [
    ["Main Dining", :indoor, 1],
    ["Private Rooms", :indoor, 2],
    ["Terrace", :outdoor, 1]
  ].each do |name, area_type, floor_level|
    area_map[name] = Area.find_or_create_by!(name: name) do |record|
      record.area_type = area_type
      record.floor_level = floor_level
    end
  end

  # --- Table types ----------------------------------------------------------
  table_types = {
    "Standard" => 0.00,
    "VIP" => 25.00,
    "Family" => 15.00
  }

  table_type_map = {}
  table_types.each do |name, price|
    table_type_map[name] = TableType.find_or_create_by!(type: name) do |record|
      record.price_add_on = price
    end
  end

  # --- Tables ---------------------------------------------------------------
  tables_to_seed = [
    { area: "Main Dining", type: "Standard", table_number: "A1", shape: :square, capacity: 2, pos_x: 80, pos_y: 80, width: 90, height: 90, status: :available },
    { area: "Main Dining", type: "Standard", table_number: "A2", shape: :square, capacity: 4, pos_x: 220, pos_y: 80, width: 90, height: 90, status: :available },
    { area: "Main Dining", type: "VIP", table_number: "V1", shape: :round, capacity: 6, pos_x: 420, pos_y: 90, radius: 48, status: :reserved },
    { area: "Main Dining", type: "Family", table_number: "F1", shape: :rectangle, capacity: 8, pos_x: 600, pos_y: 80, width: 140, height: 90, status: :available },
    { area: "Main Dining", type: "Standard", table_number: "A3", shape: :rectangle, capacity: 6, pos_x: 80, pos_y: 260, width: 120, height: 90, status: :available },
    { area: "Private Rooms", type: "VIP", table_number: "P1", shape: :round, capacity: 4, pos_x: 120, pos_y: 120, radius: 42, status: :available },
    { area: "Private Rooms", type: "Family", table_number: "P2", shape: :rectangle, capacity: 10, pos_x: 260, pos_y: 120, width: 140, height: 100, status: :available },
    { area: "Terrace", type: "Standard", table_number: "T1", shape: :square, capacity: 2, pos_x: 80, pos_y: 80, width: 90, height: 90, status: :available },
    { area: "Terrace", type: "Standard", table_number: "T2", shape: :round, capacity: 4, pos_x: 260, pos_y: 80, radius: 40, status: :available }
  ]

  tables_to_seed.each do |attrs|
    table = Table.find_or_initialize_by(area: area_map.fetch(attrs[:area]), table_number: attrs[:table_number])
    table.assign_attributes(
      table_type: table_type_map.fetch(attrs[:type]),
      capacity: attrs[:capacity],
      shape: attrs[:shape],
      pos_x: attrs[:pos_x],
      pos_y: attrs[:pos_y],
      rotation: attrs[:rotation].to_i,
      radius: attrs[:radius],
      width: attrs[:width],
      height: attrs[:height],
      status: attrs[:status]
    )
    table.save!
  end

  # --- Categories & foods ---------------------------------------------------
  categories = {
    "Starters" => [
      ["Pan-Seared Scallops with Lemon Butter Sauce", 29.00],
      ["Pan-Seared Foie Gras with Apple Sauce", 34.00],
      ["Japanese-Style Steamed Cod", 26.00],
      ["Thai-Style Prawn Curry", 24.00],
      ["Creamy Pumpkin Soup", 18.00]
    ],
    "Mains" => [
      ["Grilled Wagyu Beef with Green Peppercorn Sauce", 52.00],
      ["Miso-Glazed Seared Salmon", 38.00],
      ["Vietnamese Shaking Beef", 36.00],
      ["Truffle Mushroom Risotto", 33.00],
      ["Lobster Linguine", 42.00],
      ["Roasted Cod with Saffron Sauce", 40.00],
      ["Veal Tenderloin with Wild Mushroom Sauce", 44.00]
    ],
    "Desserts" => [
      ["Classic Vanilla Crème Brûlée", 15.00],
      ["Chocolate Fondant", 18.00],
      ["Classic Italian Tiramisu", 17.00]
    ],
    "Beverages" => [
      ["Fresh Orange Juice", 8.00],
      ["Fresh Green Apple Juice", 8.00],
      ["Peach, Orange & Lemongrass Tea", 10.00]
    ]
  }

  foods_by_name = {}
  categories.each do |category_name, menu_items|
    category = Category.find_or_create_by!(name: category_name)

    menu_items.each do |name, base_price|
      food = Food.find_or_initialize_by(name: name, category: category)
      food.assign_attributes(
        base_price: base_price,
        description: "Prepared in-house with seasonal ingredients.",
        status: :active
      )
      food.save!
      foods_by_name[name] = food
    end
  end

  # --- Food variants --------------------------------------------------------
  variant_map = {
    "Grilled Wagyu Beef with Green Peppercorn Sauce" => {
      "Medium Rare" => 0.00,
      "Well Done" => -2.00
    },
    "Veal Tenderloin with Wild Mushroom Sauce" => {
      "Extra Sauce" => 3.00,
      "No Sauce" => -2.00
    }
  }

  variant_map.each do |food_name, options|
    food = foods_by_name.fetch(food_name)
    options.each do |variant_name, adjustment|
      FoodVariant.find_or_create_by!(food: food, name: variant_name) do |record|
        record.price_adjustment = adjustment
      end
    end
  end

  # --- Ingredients ----------------------------------------------------------
  # SỬA LỖI: trước đây dùng Ingredient.find_or_create_by!(name:) rồi mới gán unit/giá/số lượng.
  # create! chạy validation ngay lúc đó nên báo "Unit can't be blank...".
  # Giờ dùng find_or_initialize_by -> gán đủ thuộc tính -> save! một lần.
  ingredients_by_name = {}
  INGREDIENT_SPECS.each do |name, unit, unit_cost, quantity, threshold, category|
    ingredient = Ingredient.find_or_initialize_by(name: name)
    ingredient.assign_attributes(
      unit: unit,
      category: category,
      unit_cost: unit_cost,
      low_stock_threshold: threshold,
      active: true
    )
    # Chỉ đặt tồn kho khi tạo mới, chạy lại seed sẽ không ghi đè tồn kho thật.
    ingredient.current_quantity = quantity * STOCK_BOOST if ingredient.new_record?
    ingredient.save!
    ingredients_by_name[name] = ingredient
  end

  # --- Recipes --------------------------------------------------------------
  RECIPE_SPECS.each do |food_name, ingredients_for_food|
    food = foods_by_name[food_name]
    next if food.nil?

    ingredients_for_food.each do |ingredient_name, quantity|
      ingredient = ingredients_by_name.fetch(ingredient_name)
      RecipeItem.find_or_create_by!(food: food, ingredient: ingredient, food_variant: nil) do |record|
        record.quantity_required = quantity.to_d
      end
    end
  end

  # --- Payment methods ------------------------------------------------------
  [
    ["Cash", :cash],
    ["Card", :card],
    ["QR Code", :qr]
  ].each do |name, code|
    PaymentMethod.find_or_create_by!(code: code) do |record|
      record.name = name
      record.active = true
    end
  end

  # --- Promotion ------------------------------------------------------------
  Promotion.find_or_create_by!(name: "Lunch Special") do |record|
    record.discount_type = true
    record.discount_value = 15
    record.start_date = Date.current.beginning_of_month
    record.end_date = Date.current + 90.days
    record.status = :published
  end

  # --- Reservations ---------------------------------------------------------
  future_date = Date.current + 2
  table_for_reservation = Table.where(status: :available).order(:id).first
  reservation = Reservation.find_or_initialize_by(
    guest_name: customer.full_name,
    reservation_date: future_date,
    table: table_for_reservation
  )
  reservation.assign_attributes(
    guest_phone: customer.phone,
    user: customer,
    reservation_time: Time.zone.local(future_date.year, future_date.month, future_date.day, 19, 0, 0),
    status: :approved,
    note: "Dinner reservation"
  )
  reservation.save!

  past_date = Date.current - 1
  past_reservation = Reservation.find_or_initialize_by(
    guest_name: customer.full_name,
    reservation_date: past_date,
    table: Table.where(status: :available).order(:id).last
  )
  past_reservation.assign_attributes(
    guest_phone: customer.phone,
    user: customer,
    reservation_time: Time.zone.local(past_date.year, past_date.month, past_date.day, 17, 0, 0),
    status: :completed,
    note: "Past reviewable reservation"
  )
  past_reservation.save!

  # --- Order + payment ------------------------------------------------------
  order = Order.find_or_initialize_by(table: table_for_reservation, reservation: reservation, user_id: waiter.id)
  order.assign_attributes(waiter: waiter, status: :inserve)
  order.save!

  if order.order_items.empty?
    item_food = foods_by_name["Grilled Wagyu Beef with Green Peppercorn Sauce"] || foods_by_name.values.first
    OrderItem.create!(order: order, food: item_food, quantity: 2, special_note: "Extra sauce")
  end

  order.recalculate_total_price!
  order.update!(status: :completed) if order.status != "completed"

  completed_payment = Payment.find_or_initialize_by(order: order) do |record|
    record.payment_method = PaymentMethod.find_by!(code: :cash)
    record.processed_by = admin
    record.currency = "VND"
  end
  completed_payment.assign_attributes(
    payment_method: PaymentMethod.find_by!(code: :cash),
    processed_by: admin,
    subtotal: order.subtotal || order.total_price,
    discount_amount: order.discount_amount || 0,
    total_amount: order.total_price || order.subtotal,
    currency: "VND",
    status: :completed,
    paid_at: Time.current
  )
  completed_payment.save!

  # --- Review ---------------------------------------------------------------
  Review.find_or_create_by!(reservation: past_reservation, user_id: customer.id) do |record|
    record.rating = 5
    record.comment = "Excellent food and service."
  end

  # --- Low stock request & waste report (dữ liệu demo) ---------------------
  low_stock_ingredient = ingredients_by_name.fetch("Lobster")
  low_stock_ingredient.update!(current_quantity: 1, low_stock_threshold: 2)
  LowStockRequest.find_or_create_by!(user: kitchen_staff, ingredient: low_stock_ingredient) do |record|
    record.note = "Need more lobster for weekend service."
    record.status = :pending
    record.urgency = :high
  end

  waste_ingredient = ingredients_by_name.fetch("Tomato")
  WasteReport.find_or_create_by!(ingredient: waste_ingredient, user: kitchen_staff) do |record|
    record.quantity = 1.5
    record.reason = "Damaged produce during prep."
    record.status = :pending
  end

  puts "Seeded users: #{User.count}"
  puts "Seeded areas: #{Area.count}"
  puts "Seeded tables: #{Table.count}"
  puts "Seeded categories: #{Category.count}"
  puts "Seeded foods: #{Food.count}"
  puts "Seeded ingredients: #{Ingredient.count}"
  puts "Seeded recipe items: #{RecipeItem.count}"
  puts "Seeded payment methods: #{PaymentMethod.count}"
  puts "Seeded promotions: #{Promotion.count}"
  puts "Seeded reservations: #{Reservation.count}"
  puts "Seeded orders: #{Order.count}"
  puts "Seeded payments: #{Payment.count}"
  puts "Seed completed successfully."
end