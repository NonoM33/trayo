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

ActiveRecord::Schema[8.0].define(version: 2025_10_23_000009) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "credits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_credits_on_created_at"
    t.index ["user_id"], name: "index_credits_on_user_id"
  end

  create_table "mt5_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "mt5_id", null: false
    t.string "account_name", null: false
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.datetime "last_sync_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "high_watermark", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_withdrawals", precision: 15, scale: 2, default: "0.0"
    t.index ["mt5_id"], name: "index_mt5_accounts_on_mt5_id", unique: true
    t.index ["user_id", "mt5_id"], name: "index_mt5_accounts_on_user_id_and_mt5_id", unique: true
    t.index ["user_id"], name: "index_mt5_accounts_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.date "payment_date", null: false
    t.string "status", default: "pending", null: false
    t.string "reference"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "mt5_account_id", null: false
    t.string "trade_id", null: false
    t.string "symbol"
    t.string "trade_type"
    t.decimal "volume", precision: 15, scale: 5
    t.decimal "open_price", precision: 15, scale: 5
    t.decimal "close_price", precision: 15, scale: 5
    t.decimal "profit", precision: 15, scale: 2
    t.decimal "commission", precision: 15, scale: 2
    t.decimal "swap", precision: 15, scale: 2
    t.datetime "open_time"
    t.datetime "close_time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["close_time"], name: "index_trades_on_close_time"
    t.index ["mt5_account_id", "trade_id"], name: "index_trades_on_mt5_account_id_and_trade_id", unique: true
    t.index ["mt5_account_id"], name: "index_trades_on_mt5_account_id"
    t.index ["open_time"], name: "index_trades_on_open_time"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mt5_api_token"
    t.decimal "commission_rate", precision: 5, scale: 2, default: "0.0"
    t.boolean "is_admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["mt5_api_token"], name: "index_users_on_mt5_api_token", unique: true
  end

  create_table "withdrawals", force: :cascade do |t|
    t.bigint "mt5_account_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "withdrawal_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mt5_account_id"], name: "index_withdrawals_on_mt5_account_id"
    t.index ["withdrawal_date"], name: "index_withdrawals_on_withdrawal_date"
  end

  add_foreign_key "credits", "users"
  add_foreign_key "mt5_accounts", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "trades", "mt5_accounts"
  add_foreign_key "withdrawals", "mt5_accounts"
end
