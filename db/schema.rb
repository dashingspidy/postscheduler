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

ActiveRecord::Schema[8.1].define(version: 2026_07_27_110700) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
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
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "content_topics", force: :cascade do |t|
    t.string "angle"
    t.datetime "created_at", null: false
    t.integer "daily_slot", default: 1, null: false
    t.string "hook_style"
    t.string "pillar", null: false
    t.integer "project_id", null: false
    t.date "scheduled_for", null: false
    t.integer "slideshow_id"
    t.string "status", default: "planned", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "zernio_account_id"
    t.index ["project_id", "pillar", "angle"], name: "index_content_topics_on_project_id_and_pillar_and_angle"
    t.index ["project_id"], name: "index_content_topics_on_project_id"
    t.index ["slideshow_id"], name: "index_content_topics_on_slideshow_id"
    t.index ["zernio_account_id", "scheduled_for", "daily_slot"], name: "index_content_topics_on_account_date_and_slot", unique: true
    t.index ["zernio_account_id"], name: "index_content_topics_on_zernio_account_id"
  end

  create_table "posts", force: :cascade do |t|
    t.json "account_ids", default: {}, null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "delivery_mode", default: "auto_publish", null: false
    t.json "platforms", default: [], null: false
    t.integer "project_id"
    t.string "provider_post_id"
    t.string "publishing_provider", default: "zernio", null: false
    t.datetime "scheduled_at"
    t.string "status", default: "draft", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "zernio_post_id"
    t.index ["project_id"], name: "index_posts_on_project_id"
    t.index ["publishing_provider", "provider_post_id"], name: "index_posts_on_publishing_provider_and_provider_post_id", unique: true
    t.index ["scheduled_at"], name: "index_posts_on_scheduled_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["zernio_post_id"], name: "index_posts_on_zernio_post_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "default_slide_count", default: 5, null: false
    t.boolean "factory_enabled", default: false, null: false
    t.string "factory_time", default: "09:00", null: false
    t.string "name", null: false
    t.string "publishing_provider", default: "zernio", null: false
    t.json "style", default: {}, null: false
    t.string "tiktok_account_id"
    t.string "time_zone", default: "Europe/Brussels", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "slideshow_targets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "slideshow_id", null: false
    t.datetime "updated_at", null: false
    t.integer "zernio_account_id", null: false
    t.index ["slideshow_id", "zernio_account_id"], name: "index_slideshow_import_targets_uniqueness", unique: true
    t.index ["slideshow_id"], name: "index_slideshow_targets_on_slideshow_id"
    t.index ["zernio_account_id"], name: "index_slideshow_targets_on_zernio_account_id"
  end

  create_table "slideshows", force: :cascade do |t|
    t.integer "content_topic_id"
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.string "delivery_mode", default: "tiktok_draft", null: false
    t.text "error_message"
    t.date "factory_date"
    t.integer "factory_slot", default: 1, null: false
    t.datetime "first_delivery_at"
    t.integer "post_id"
    t.integer "project_id"
    t.text "prompt"
    t.integer "slide_count", default: 5, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "zernio_account_id"
    t.index ["content_topic_id"], name: "index_slideshows_on_content_topic_id"
    t.index ["post_id"], name: "index_slideshows_on_post_id"
    t.index ["project_id"], name: "index_slideshows_on_project_id"
    t.index ["user_id"], name: "index_slideshows_on_user_id"
    t.index ["zernio_account_id", "factory_date", "factory_slot"], name: "index_slideshows_on_account_date_and_slot", unique: true, where: "factory_date IS NOT NULL"
    t.index ["zernio_account_id"], name: "index_slideshows_on_zernio_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "video_creations", force: :cascade do |t|
    t.string "call_to_action", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "post_id"
    t.integer "project_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_video_creations_on_post_id"
    t.index ["project_id"], name: "index_video_creations_on_project_id"
    t.index ["user_id"], name: "index_video_creations_on_user_id"
  end

  create_table "zernio_accounts", force: :cascade do |t|
    t.string "account_id", null: false
    t.boolean "active", default: true, null: false
    t.json "content_pillar_weights", default: {}, null: false
    t.json "content_pillars", default: [], null: false
    t.text "content_strategy"
    t.datetime "created_at", null: false
    t.boolean "factory_enabled", default: true, null: false
    t.integer "factory_posts_per_day", default: 10, null: false
    t.string "label", null: false
    t.string "platform", null: false
    t.integer "project_id", null: false
    t.string "provider", default: "zernio", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "provider", "account_id"], name: "idx_on_project_id_provider_account_id_f4c2445654", unique: true
    t.index ["project_id"], name: "index_zernio_accounts_on_project_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "content_topics", "projects"
  add_foreign_key "content_topics", "slideshows"
  add_foreign_key "content_topics", "zernio_accounts"
  add_foreign_key "posts", "projects"
  add_foreign_key "posts", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "slideshow_targets", "slideshows"
  add_foreign_key "slideshow_targets", "zernio_accounts"
  add_foreign_key "slideshows", "content_topics"
  add_foreign_key "slideshows", "posts"
  add_foreign_key "slideshows", "projects"
  add_foreign_key "slideshows", "users"
  add_foreign_key "slideshows", "zernio_accounts"
  add_foreign_key "video_creations", "posts"
  add_foreign_key "video_creations", "projects"
  add_foreign_key "video_creations", "users"
  add_foreign_key "zernio_accounts", "projects"
end
