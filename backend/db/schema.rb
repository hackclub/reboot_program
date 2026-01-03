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

ActiveRecord::Schema[8.0].define(version: 2026_01_03_100808) do
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
  end

  create_table "shop_orders", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shop_item_id", null: false
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
  end

  add_foreign_key "shop_orders", "shop_items"
  add_foreign_key "shop_orders", "users"
end
