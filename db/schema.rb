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

ActiveRecord::Schema[8.1].define(version: 2026_09_22_152527) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "dishes", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_dishes_on_user_id_and_name_alive", unique: true, where: "(deleted_at IS NULL)"
    t.index ["user_id"], name: "index_dishes_on_user_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dish_id", null: false
    t.text "items_for_improvement"
    t.bigint "menu_id", null: false
    t.decimal "portion_size", precision: 6, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.decimal "weight_of_leftovers", precision: 6, scale: 2
    t.index ["dish_id"], name: "index_menu_items_on_dish_id"
    t.index ["menu_id", "dish_id"], name: "index_menu_items_on_menu_id_and_dish_id", unique: true
    t.index ["menu_id"], name: "index_menu_items_on_menu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.integer "attendance_count"
    t.datetime "created_at", null: false
    t.date "date_provided", null: false
    t.boolean "excluded_from_stats", default: false, null: false
    t.text "exclusion_reason"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "date_provided"], name: "index_menus_on_user_id_and_date_provided", unique: true
    t.index ["user_id"], name: "index_menus_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "academic_year", null: false
    t.datetime "created_at", null: false
    t.integer "current_enrollment", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "school_name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "dishes", "users"
  add_foreign_key "menu_items", "dishes"
  add_foreign_key "menu_items", "menus"
  add_foreign_key "menus", "users"
end
