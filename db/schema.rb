# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_02_063740) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "areas", force: :cascade do |t|
    t.integer "area_type"
    t.datetime "created_at", null: false
    t.integer "floor_level"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name"
  end

  create_table "customer_queues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "guest_name"
    t.string "guest_phone"
    t.string "note"
    t.integer "status"
    t.bigint "table_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["table_id"], name: "index_customer_queues_on_table_id"
    t.index ["user_id"], name: "index_customer_queues_on_user_id"
  end

  create_table "food_variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "food_id", null: false
    t.string "name"
    t.decimal "price_adjustment", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["food_id"], name: "index_food_variants_on_food_id"
  end

  create_table "foods", force: :cascade do |t|
    t.decimal "base_price", precision: 10, scale: 2
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_foods_on_category_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", default: "other", null: false
    t.datetime "created_at", null: false
    t.decimal "current_quantity", precision: 10, scale: 2
    t.decimal "low_stock_threshold", precision: 10, scale: 2
    t.string "name"
    t.integer "status", default: 0, null: false
    t.string "unit"
    t.decimal "unit_cost", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_ingredients_on_active"
    t.index ["category"], name: "index_ingredients_on_category"
    t.index ["name"], name: "index_ingredients_on_name", unique: true
    t.index ["status"], name: "index_ingredients_on_status"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "low_stock_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.text "note"
    t.text "review_note"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "urgency", default: 0, null: false
    t.bigint "user_id", null: false
    t.index ["ingredient_id", "status"], name: "index_low_stock_requests_on_ingredient_id_and_status"
    t.index ["ingredient_id"], name: "index_low_stock_requests_on_ingredient_id"
    t.index ["reviewed_by_id"], name: "index_low_stock_requests_on_reviewed_by_id"
    t.index ["status"], name: "index_low_stock_requests_on_status"
    t.index ["urgency"], name: "index_low_stock_requests_on_urgency"
    t.index ["user_id"], name: "index_low_stock_requests_on_user_id"
  end

  create_table "member_tiers", force: :cascade do |t|
    t.integer "active_price"
    t.datetime "created_at", null: false
    t.integer "discount"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at", null: false
    t.bigint "recipient_id", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "status"], name: "index_notifications_on_recipient_id_and_status"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "food_id", null: false
    t.bigint "food_variant_id"
    t.bigint "order_id", null: false
    t.integer "quantity"
    t.text "special_note"
    t.integer "status", default: 0
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index ["food_id"], name: "index_order_items_on_food_id"
    t.index ["food_variant_id"], name: "index_order_items_on_food_variant_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "discount_amount"
    t.bigint "promotion_id"
    t.datetime "released_to_kitchen_at"
    t.bigint "reservation_id"
    t.integer "status"
    t.decimal "subtotal"
    t.bigint "table_id", null: false
    t.decimal "table_price", precision: 10, scale: 2
    t.decimal "total_price", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["reservation_id"], name: "index_orders_on_reservation_id"
    t.index ["status", "released_to_kitchen_at"], name: "index_orders_on_status_and_released_to_kitchen_at"
    t.index ["table_id"], name: "index_orders_on_table_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.boolean "active"
    t.integer "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_payment_methods_on_code", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.decimal "discount_amount"
    t.text "failure_reason"
    t.string "idempotency_key"
    t.bigint "order_id", null: false
    t.datetime "paid_at"
    t.bigint "payment_method_id", null: false
    t.bigint "processed_by_id"
    t.text "qr_code_data"
    t.datetime "refunded_at"
    t.integer "status"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.decimal "subtotal"
    t.decimal "total_amount"
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_payments_on_idempotency_key", unique: true
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["payment_method_id"], name: "index_payments_on_payment_method_id"
    t.index ["processed_by_id"], name: "index_payments_on_processed_by_id"
    t.index ["stripe_checkout_session_id"], name: "index_payments_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_payments_on_stripe_payment_intent_id", unique: true
  end

  create_table "promotions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "discount_type"
    t.decimal "discount_value", precision: 10, scale: 2
    t.datetime "end_date"
    t.string "name"
    t.datetime "start_date"
    t.integer "status"
    t.datetime "updated_at", null: false
  end

  create_table "recipe_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "food_id", null: false
    t.bigint "food_variant_id"
    t.bigint "ingredient_id", null: false
    t.decimal "quantity_required", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["food_id"], name: "index_recipe_items_on_food_id"
    t.index ["food_variant_id"], name: "index_recipe_items_on_food_variant_id"
    t.index ["ingredient_id"], name: "index_recipe_items_on_ingredient_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "guest_name"
    t.string "guest_phone"
    t.string "note"
    t.date "reservation_date"
    t.time "reservation_time"
    t.integer "status"
    t.bigint "table_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["table_id"], name: "index_reservations_on_table_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "restock_tasks", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "due_on"
    t.bigint "ingredient_id", null: false
    t.bigint "low_stock_request_id"
    t.string "note"
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.decimal "received_quantity", precision: 10, scale: 2
    t.integer "source", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "supplier"
    t.datetime "updated_at", null: false
    t.bigint "waste_report_id"
    t.index ["ingredient_id"], name: "index_restock_tasks_on_ingredient_id"
    t.index ["low_stock_request_id"], name: "index_restock_tasks_on_low_stock_request_id"
    t.index ["source"], name: "index_restock_tasks_on_source"
    t.index ["status"], name: "index_restock_tasks_on_status"
    t.index ["waste_report_id"], name: "index_restock_tasks_on_waste_report_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "rating", null: false
    t.bigint "reservation_id", null: false
    t.integer "review_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["reservation_id"], name: "index_reviews_on_reservation_id"
    t.index ["reservation_id"], name: "index_reviews_unique_meal_per_reservation", unique: true, where: "(review_type = 0)"
    t.index ["review_type"], name: "index_reviews_on_review_type"
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.index ["user_id"], name: "index_reviews_unique_restaurant_per_customer", unique: true, where: "(review_type = 1)"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "reviews_rating_range"
  end

  create_table "stock_transactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.decimal "quantity_after", precision: 10, scale: 2
    t.decimal "quantity_before", precision: 10, scale: 2
    t.string "reason"
    t.string "reference", limit: 80
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["ingredient_id", "created_at"], name: "index_stock_transactions_on_ingredient_id_and_created_at"
    t.index ["ingredient_id"], name: "index_stock_transactions_on_ingredient_id"
    t.index ["transaction_type"], name: "index_stock_transactions_on_transaction_type"
    t.index ["user_id"], name: "index_stock_transactions_on_user_id"
  end

  create_table "table_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "price_add_on", precision: 10, scale: 2
    t.string "type"
    t.datetime "updated_at", null: false
  end

  create_table "tables", force: :cascade do |t|
    t.bigint "area_id", null: false
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.decimal "height", precision: 8, scale: 2
    t.decimal "pos_x", precision: 8, scale: 2
    t.decimal "pos_y", precision: 8, scale: 2
    t.decimal "radius", precision: 8, scale: 2
    t.integer "rotation"
    t.integer "shape"
    t.integer "status"
    t.string "table_number"
    t.bigint "table_type_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "width", precision: 8, scale: 2
    t.index ["area_id"], name: "index_tables_on_area_id"
    t.index ["table_type_id"], name: "index_tables_on_table_type_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name", null: false
    t.string "jti", null: false
    t.string "location"
    t.bigint "member_tier_id"
    t.string "phone", null: false
    t.datetime "remember_created_at"
    t.string "remember_token"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.boolean "status", default: true, null: false
    t.datetime "updated_at", null: false
    t.decimal "year_spend", precision: 10, scale: 2
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["member_tier_id"], name: "index_users_on_member_tier_id"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "waste_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.text "reason"
    t.text "review_note"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.decimal "verified_quantity", precision: 10, scale: 2
    t.index ["ingredient_id", "created_at"], name: "index_waste_reports_on_ingredient_id_and_created_at"
    t.index ["ingredient_id"], name: "index_waste_reports_on_ingredient_id"
    t.index ["reviewed_by_id"], name: "index_waste_reports_on_reviewed_by_id"
    t.index ["status"], name: "index_waste_reports_on_status"
    t.index ["user_id"], name: "index_waste_reports_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customer_queues", "tables"
  add_foreign_key "customer_queues", "users"
  add_foreign_key "food_variants", "foods"
  add_foreign_key "foods", "categories"
  add_foreign_key "low_stock_requests", "ingredients"
  add_foreign_key "low_stock_requests", "users"
  add_foreign_key "low_stock_requests", "users", column: "reviewed_by_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "order_items", "food_variants"
  add_foreign_key "order_items", "foods"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "promotions"
  add_foreign_key "orders", "reservations"
  add_foreign_key "orders", "tables"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "orders"
  add_foreign_key "payments", "payment_methods"
  add_foreign_key "payments", "users", column: "processed_by_id"
  add_foreign_key "recipe_items", "food_variants"
  add_foreign_key "recipe_items", "foods"
  add_foreign_key "recipe_items", "ingredients"
  add_foreign_key "reservations", "tables"
  add_foreign_key "reservations", "users"
  add_foreign_key "restock_tasks", "ingredients"
  add_foreign_key "restock_tasks", "low_stock_requests"
  add_foreign_key "restock_tasks", "waste_reports"
  add_foreign_key "reviews", "reservations"
  add_foreign_key "reviews", "users"
  add_foreign_key "stock_transactions", "ingredients"
  add_foreign_key "stock_transactions", "users"
  add_foreign_key "tables", "areas"
  add_foreign_key "tables", "table_types"
  add_foreign_key "users", "member_tiers"
  add_foreign_key "waste_reports", "ingredients"
  add_foreign_key "waste_reports", "users"
  add_foreign_key "waste_reports", "users", column: "reviewed_by_id"
end
