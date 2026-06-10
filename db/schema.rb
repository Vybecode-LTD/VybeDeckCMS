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

ActiveRecord::Schema[8.1].define(version: 2026_06_09_210300) do
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

  create_table "chat_channels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.boolean "is_private", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_chat_channels_on_created_by_id"
    t.index ["name"], name: "index_chat_channels_on_name", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body"
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "edited_at"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_chat_messages_on_author_id"
    t.index ["chat_channel_id", "created_at"], name: "index_chat_messages_on_channel_and_time"
    t.index ["chat_channel_id"], name: "index_chat_messages_on_chat_channel_id"
  end

  create_table "chat_reactions", force: :cascade do |t|
    t.bigint "chat_message_id", null: false
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_message_id", "user_id", "emoji"], name: "index_chat_reactions_unique", unique: true
    t.index ["chat_message_id"], name: "index_chat_reactions_on_chat_message_id"
    t.index ["user_id"], name: "index_chat_reactions_on_user_id"
  end

  create_table "forum_replies", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.bigint "forum_thread_id", null: false
    t.boolean "is_solution", default: false, null: false
    t.integer "likes_count", default: 0, null: false
    t.text "report_reason"
    t.datetime "reported_at"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_forum_replies_on_author_id"
    t.index ["forum_thread_id", "created_at"], name: "index_forum_replies_on_forum_thread_id_and_created_at"
    t.index ["forum_thread_id"], name: "index_forum_replies_on_forum_thread_id"
    t.index ["is_solution"], name: "index_forum_replies_on_is_solution"
    t.index ["reported_at"], name: "index_forum_replies_on_reported_at"
  end

  create_table "forum_threads", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.bigint "forum_id", null: false
    t.datetime "last_reply_at"
    t.boolean "locked", default: false, null: false
    t.boolean "pinned", default: false, null: false
    t.integer "reply_count", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0, null: false
    t.index ["author_id"], name: "index_forum_threads_on_author_id"
    t.index ["forum_id", "pinned", "last_reply_at"], name: "index_forum_threads_on_forum_id_and_pinned_and_last_reply_at"
    t.index ["forum_id"], name: "index_forum_threads_on_forum_id"
    t.index ["last_reply_at"], name: "index_forum_threads_on_last_reply_at"
    t.index ["locked"], name: "index_forum_threads_on_locked"
    t.index ["pinned"], name: "index_forum_threads_on_pinned"
  end

  create_table "forums", force: :cascade do |t|
    t.string "colour_hex"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["position"], name: "index_forums_on_position"
    t.index ["slug"], name: "index_forums_on_slug", unique: true
    t.index ["visibility"], name: "index_forums_on_visibility"
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

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "likeable_id", null: false
    t.string "likeable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id", "likeable_type", "likeable_id"], name: "index_likes_on_user_and_likeable", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
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

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_read"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "confirmation_email_sent_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "gbp", null: false
    t.string "email", null: false
    t.datetime "refund_receipt_sent_at"
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
  add_foreign_key "chat_channels", "users", column: "created_by_id"
  add_foreign_key "chat_messages", "chat_channels"
  add_foreign_key "chat_messages", "users", column: "author_id"
  add_foreign_key "chat_reactions", "chat_messages"
  add_foreign_key "chat_reactions", "users"
  add_foreign_key "forum_replies", "forum_threads"
  add_foreign_key "forum_replies", "users", column: "author_id"
  add_foreign_key "forum_threads", "forums"
  add_foreign_key "forum_threads", "users", column: "author_id"
  add_foreign_key "impersonation_logs", "users", column: "impersonated_id"
  add_foreign_key "impersonation_logs", "users", column: "impersonator_id"
  add_foreign_key "likes", "users"
  add_foreign_key "line_items", "orders"
  add_foreign_key "line_items", "prices"
  add_foreign_key "line_items", "products"
  add_foreign_key "media", "users", column: "uploaded_by_id"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
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
