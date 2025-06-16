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

ActiveRecord::Schema[8.0].define(version: 2025_01_16_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "streams", force: :cascade do |t|
    t.string "url", null: false
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.string "status", default: "active"
    t.boolean "is_pinned", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_pinned"], name: "index_streams_on_is_pinned"
    t.index ["status"], name: "index_streams_on_status"
    t.index ["user_id", "created_at"], name: "index_streams_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_streams_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "streams", "users"
end
