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

ActiveRecord::Schema[8.1].define(version: 2025_12_11_200912) do
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

  create_table "brand_colors", force: :cascade do |t|
    t.integer "brand_id", null: false
    t.datetime "created_at", null: false
    t.string "hex_value"
    t.boolean "primary"
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_brand_colors_on_brand_id"
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "tone_of_voice"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_brands_on_user_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.integer "brand_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "product_name"
    t.integer "status", default: 0, null: false
    t.string "target_audience"
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_campaigns_on_brand_id"
    t.index ["status"], name: "index_campaigns_on_status"
  end

  create_table "creatives", force: :cascade do |t|
    t.integer "ai_cost_cents"
    t.json "ai_metadata", default: {}
    t.string "ai_model"
    t.integer "ai_tokens"
    t.text "background_prompt"
    t.text "body"
    t.integer "campaign_id", null: false
    t.datetime "created_at", null: false
    t.string "headline"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_creatives_on_campaign_id"
    t.index ["status"], name: "index_creatives_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "brand_colors", "brands"
  add_foreign_key "brands", "users"
  add_foreign_key "campaigns", "brands"
  add_foreign_key "creatives", "campaigns"
  add_foreign_key "sessions", "users"
end
