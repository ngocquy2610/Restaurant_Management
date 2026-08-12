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

ActiveRecord::Schema[8.1].define(version: 2026_08_11_034749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "areas", force: :cascade do |t|
    t.integer "area_type"
    t.datetime "created_at", null: false
    t.integer "floor_level"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
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
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "full_name", null: false
    t.string "jti", null: false
    t.string "location"
    t.datetime "locked_at"
    t.string "phone", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.boolean "status", default: true, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "tables", "areas"
  add_foreign_key "tables", "table_types"
end
