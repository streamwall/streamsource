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

ActiveRecord::Schema[8.0].define(version: 2025_07_10_010745) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key"], name: "index_flipper_gates_on_feature_key_and_key", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_jwt_denylists_on_exp"
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "city", null: false
    t.string "state_province"
    t.string "region"
    t.string "country"
    t.string "normalized_name", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.boolean "is_known_city", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city", "state_province", "country"], name: "index_locations_on_city_and_state_province_and_country"
    t.index ["city"], name: "index_locations_on_city"
    t.index ["country"], name: "index_locations_on_country"
    t.index ["is_known_city"], name: "index_locations_on_is_known_city"
    t.index ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude"
    t.index ["normalized_name"], name: "index_locations_on_normalized_name", unique: true
    t.index ["state_province"], name: "index_locations_on_state_province"
  end

  create_table "streamer_accounts", force: :cascade do |t|
    t.bigint "streamer_id", null: false
    t.string "platform", null: false
    t.string "username", null: false
    t.string "profile_url"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform"], name: "index_streamer_accounts_on_platform"
    t.index ["streamer_id", "platform", "username"], name: "idx_streamer_platform_username", unique: true
    t.index ["streamer_id"], name: "index_streamer_accounts_on_streamer_id"
  end

  create_table "streamers", force: :cascade do |t|
    t.string "name", null: false
    t.text "notes"
    t.string "posted_by"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_streamers_on_name"
    t.index ["user_id"], name: "index_streamers_on_user_id"
  end

  create_table "streams", force: :cascade do |t|
    t.string "link", null: false
    t.string "source", null: false
    t.bigint "user_id", null: false
    t.boolean "is_pinned", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
    t.string "state"
    t.string "platform"
    t.string "status", default: "Unknown"
    t.text "notes"
    t.string "title"
    t.datetime "last_checked_at"
    t.datetime "last_live_at"
    t.string "posted_by"
    t.string "orientation"
    t.string "kind", default: "video"
    t.bigint "streamer_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.boolean "is_archived", default: false
    t.bigint "location_id"
    t.index ["ended_at"], name: "index_streams_on_ended_at"
    t.index ["is_archived"], name: "index_streams_on_is_archived"
    t.index ["is_pinned"], name: "index_streams_on_is_pinned"
    t.index ["kind"], name: "index_streams_on_kind"
    t.index ["last_checked_at"], name: "index_streams_on_last_checked_at"
    t.index ["last_live_at"], name: "index_streams_on_last_live_at"
    t.index ["location_id"], name: "index_streams_on_location_id"
    t.index ["platform"], name: "index_streams_on_platform"
    t.index ["started_at"], name: "index_streams_on_started_at"
    t.index ["status"], name: "index_streams_on_status"
    t.index ["streamer_id", "is_archived"], name: "index_streams_on_streamer_id_and_is_archived"
    t.index ["streamer_id"], name: "index_streams_on_streamer_id"
    t.index ["user_id", "created_at"], name: "index_streams_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_streams_on_user_id"
  end

  create_table "timestamp_streams", force: :cascade do |t|
    t.bigint "timestamp_id", null: false
    t.bigint "stream_id", null: false
    t.bigint "added_by_user_id", null: false
    t.integer "stream_timestamp_seconds"
    t.string "stream_timestamp_display"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_user_id"], name: "index_timestamp_streams_on_added_by_user_id"
    t.index ["stream_id"], name: "index_timestamp_streams_on_stream_id"
    t.index ["stream_timestamp_seconds"], name: "index_timestamp_streams_on_stream_timestamp_seconds"
    t.index ["timestamp_id", "stream_id"], name: "index_timestamp_streams_on_timestamp_id_and_stream_id", unique: true
    t.index ["timestamp_id"], name: "index_timestamp_streams_on_timestamp_id"
  end

  create_table "timestamps", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "event_timestamp", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_timestamp"], name: "index_timestamps_on_event_timestamp"
    t.index ["user_id"], name: "index_timestamps_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "role", default: "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "streamer_accounts", "streamers"
  add_foreign_key "streamers", "users"
  add_foreign_key "streams", "locations"
  add_foreign_key "streams", "streamers"
  add_foreign_key "streams", "users"
  add_foreign_key "timestamp_streams", "streams"
  add_foreign_key "timestamp_streams", "timestamps"
  add_foreign_key "timestamp_streams", "users", column: "added_by_user_id"
  add_foreign_key "timestamps", "users"
end
