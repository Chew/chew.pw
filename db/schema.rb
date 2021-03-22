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

ActiveRecord::Schema.define(version: 2020_12_05_194150) do

  create_table "chewbotcca_commands", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "command", limit: 32, null: false
    t.text "args"
    t.text "flags"
    t.text "description", null: false
    t.text "examples"
    t.text "aliases"
    t.text "module"
    t.text "bot_permissions"
    t.text "user_permissions"
    t.index ["command"], name: "command", unique: true
  end

  create_table "chewbotcca_profiles", primary_key: "userid", id: :bigint, default: nil, charset: "utf8", force: :cascade do |t|
    t.text "lastfm"
    t.text "github"
  end

  create_table "chewbotcca_server_emojis", id: false, charset: "utf8", force: :cascade do |t|
    t.bigint "id", null: false
    t.json "emojis", null: false
  end

  create_table "chewbotcca_servers", primary_key: "serverid", id: :bigint, default: nil, charset: "utf8", force: :cascade do |t|
    t.text "prefix"
    t.boolean "bypass_urban_nsfw", default: false, null: false
  end

  create_table "hq_questions", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "region", null: false
    t.text "question", null: false
    t.text "option1", null: false
    t.text "option2", null: false
    t.text "option3", null: false
    t.integer "correct", null: false
    t.integer "ques_num", null: false
    t.text "time", null: false
    t.text "prize", null: false
    t.integer "picked1", null: false
    t.integer "picked2", null: false
    t.integer "picked3", null: false
    t.integer "winners", null: false
    t.text "payout", null: false
    t.text "currency", null: false
    t.text "category", null: false
    t.text "category_slug", null: false
  end

  create_table "hqtriviabot_logins", primary_key: "userid", id: :bigint, default: nil, charset: "utf8", force: :cascade do |t|
    t.text "access_token", null: false
    t.text "refresh_token", null: false
  end

  create_table "hqtriviabot_profiles", primary_key: "userid", id: :bigint, default: nil, charset: "utf8", force: :cascade do |t|
    t.text "username", null: false, collation: "utf8mb4_bin"
    t.text "region", null: false
    t.text "keyid"
    t.boolean "authkey", default: false, null: false
    t.boolean "bughunter", default: false, null: false
    t.boolean "lives", default: false, null: false
    t.boolean "streaks", default: false, null: false
    t.boolean "erase1s", default: false, null: false
    t.boolean "superspins", default: false, null: false
    t.boolean "coins", default: false, null: false
    t.boolean "donator", default: false, null: false
  end

  create_table "mcpro_faq", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "data", size: :long, null: false
    t.boolean "hidden", default: false, null: false
    t.timestamp "last_updated", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

end
