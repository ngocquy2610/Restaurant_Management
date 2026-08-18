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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_033643) do
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
    t.datetime "created_at", null: false
    t.decimal "current_stock", precision: 10, scale: 2
    t.decimal "low_stock_threshold", precision: 10, scale: 2
    t.string "name"
    t.string "unit"
    t.decimal "unit_cost", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "recipe_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "food_id", null: false
    t.bigint "food_variant_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity_required", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["food_id"], name: "index_recipe_items_on_food_id"
    t.index ["food_variant_id"], name: "index_recipe_items_on_food_variant_id"
    t.index ["ingredient_id"], name: "index_recipe_items_on_ingredient_id"
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
    t.string "phone", null: false
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.boolean "status", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "food_variants", "foods"
  add_foreign_key "foods", "categories"
  add_foreign_key "recipe_items", "food_variants"
  add_foreign_key "recipe_items", "foods"
  add_foreign_key "recipe_items", "ingredients"
  add_foreign_key "tables", "areas"
  add_foreign_key "tables", "table_types"
end
