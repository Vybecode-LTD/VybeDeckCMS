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

ActiveRecord::Schema[8.1].define(version: 2026_06_09_130001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "price_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["price_id"], name: "index_cart_items_on_price_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_carts_on_user_id", unique: true, where: "(user_id IS NOT NULL)"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "impersonation_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.bigint "impersonated_id", null: false
    t.bigint "impersonator_id", null: false
    t.bigint "impersonator_session_id"
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.index ["impersonated_id"], name: "index_impersonation_logs_on_impersonated_id"
    t.index ["impersonator_id"], name: "index_impersonation_logs_on_impersonator_id"
    t.index ["impersonator_session_id"], name: "index_impersonation_logs_on_impersonator_session_id"
  end

  create_table "line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.bigint "price_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_amount_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_line_items_on_order_id"
    t.index ["price_id"], name: "index_line_items_on_price_id"
    t.index ["product_id"], name: "index_line_items_on_product_id"
  end

  create_table "media", force: :cascade do |t|
    t.string "alt_text"
    t.bigint "byte_size"
    t.text "caption"
    t.datetime "created_at", null: false
    t.float "duration_seconds"
    t.integer "file_type", default: 0, null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "title", default: "", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.index ["created_at"], name: "index_media_on_created_at"
    t.index ["file_type"], name: "index_media_on_file_type"
    t.index ["owner_type", "owner_id"], name: "index_media_on_owner"
    t.index ["uploaded_by_id"], name: "index_media_on_uploaded_by_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "gbp", null: false
    t.string "email", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_customer_id"
    t.string "stripe_payment_intent_id"
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["email"], name: "index_orders_on_email"
    t.index ["stripe_payment_intent_id"], name: "index_orders_on_stripe_payment_intent_id", unique: true, where: "(stripe_payment_intent_id IS NOT NULL)"
    t.index ["user_id", "status"], name: "index_orders_on_user_id_and_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "meta_description"
    t.string "meta_title"
    t.integer "parent_id"
    t.integer "position", default: 0
    t.datetime "published_at"
    t.boolean "show_in_nav", default: false
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_pages_on_parent_id"
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.text "meta_description"
    t.string "meta_title"
    t.datetime "published_at"
    t.boolean "requires_subscriber", default: false, null: false
    t.bigint "series_id"
    t.integer "series_position"
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_posts_on_author_id"
    t.index ["requires_subscriber"], name: "index_posts_on_requires_subscriber"
    t.index ["series_id", "series_position"], name: "index_posts_on_series_id_and_series_position"
    t.index ["series_id"], name: "index_posts_on_series_id"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "prices", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "gbp", null: false
    t.string "nickname"
    t.bigint "product_id", null: false
    t.string "stripe_price_id"
    t.datetime "updated_at", null: false
    t.index ["product_id", "active"], name: "index_prices_on_product_id_and_active"
    t.index ["product_id"], name: "index_prices_on_product_id"
    t.index ["stripe_price_id"], name: "index_prices_on_stripe_price_id", unique: true, where: "(stripe_price_id IS NOT NULL)"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "productable_id"
    t.string "productable_type"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_product_id"
    t.datetime "updated_at", null: false
    t.index ["productable_type", "productable_id"], name: "index_products_on_productable"
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["stripe_product_id"], name: "index_products_on_stripe_product_id", unique: true, where: "(stripe_product_id IS NOT NULL)"
  end

  create_table "series", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "post_count", default: 0, null: false
    t.string "slug", default: "", null: false
    t.string "title", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_series_on_created_at"
    t.index ["slug"], name: "index_series_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", default: "", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "value_type", default: "string", null: false
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "stripe_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "stripe_customer_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["stripe_customer_id"], name: "index_stripe_customers_on_stripe_customer_id", unique: true
    t.index ["user_id"], name: "index_stripe_customers_on_user_id", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_taggings_on_category_id"
    t.index ["post_id", "category_id"], name: "index_taggings_on_post_id_and_category_id", unique: true
    t.index ["post_id"], name: "index_taggings_on_post_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "banned_at"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email_address", null: false
    t.datetime "email_verification_sent_at"
    t.string "email_verification_token"
    t.datetime "email_verified_at"
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index "lower((display_name)::text)", name: "index_users_on_lower_display_name", unique: true, where: "((display_name IS NOT NULL) AND ((display_name)::text <> ''::text))"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true, where: "(email_verification_token IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "prices"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "impersonation_logs", "users", column: "impersonated_id"
  add_foreign_key "impersonation_logs", "users", column: "impersonator_id"
  add_foreign_key "line_items", "orders"
  add_foreign_key "line_items", "prices"
  add_foreign_key "line_items", "products"
  add_foreign_key "media", "users", column: "uploaded_by_id"
  add_foreign_key "orders", "users"
  add_foreign_key "pages", "pages", column: "parent_id"
  add_foreign_key "posts", "series"
  add_foreign_key "posts", "users", column: "author_id"
  add_foreign_key "prices", "products"
  add_foreign_key "sessions", "users"
  add_foreign_key "stripe_customers", "users"
  add_foreign_key "taggings", "categories"
  add_foreign_key "taggings", "posts"
end
