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

ActiveRecord::Schema[8.0].define(version: 2026_01_03_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "shop_items", force: :cascade do |t|
    t.string "name"
    t.decimal "cost"
    t.string "status"
    t.string "description"
    t.string "link"
    t.decimal "price"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "airtable_id"
    t.index ["airtable_id"], name: "index_shop_items_on_airtable_id", unique: true
  end

  create_table "shop_orders", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shop_item_id", null: false
    t.string "airtable_id"
    t.index ["airtable_id"], name: "index_shop_orders_on_airtable_id", unique: true
    t.index ["shop_item_id"], name: "index_shop_orders_on_shop_item_id"
    t.index ["user_id"], name: "index_shop_orders_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "airtable_id"
    t.string "projects"
    t.string "slack_id"
    t.string "slack_username"
    t.date "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "provider"
    t.string "uid"
    t.boolean "idv_verified", default: false
    t.datetime "idv_verified_at"
    t.string "hca_token"
    t.datetime "hca_token_expires_at"
    t.string "role", default: "user", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "shop_orders", "shop_items"
  add_foreign_key "shop_orders", "users"
end
