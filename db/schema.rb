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

ActiveRecord::Schema[8.0].define(version: 2025_11_29_133558) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "backtests", force: :cascade do |t|
    t.bigint "trading_bot_id", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "total_trades"
    t.integer "winning_trades"
    t.integer "losing_trades"
    t.decimal "total_profit", precision: 15, scale: 2
    t.decimal "max_drawdown", precision: 10, scale: 2
    t.decimal "win_rate", precision: 5, scale: 2
    t.decimal "average_profit", precision: 15, scale: 2
    t.decimal "projection_monthly_min", precision: 15, scale: 2
    t.decimal "projection_monthly_max", precision: 15, scale: 2
    t.decimal "projection_yearly", precision: 15, scale: 2
    t.string "file_path"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_filename"
    t.index ["is_active"], name: "index_backtests_on_is_active"
    t.index ["trading_bot_id"], name: "index_backtests_on_trading_bot_id"
  end

  create_table "banner_dismissals", force: :cascade do |t|
    t.bigint "banner_id", null: false
    t.bigint "user_id", null: false
    t.datetime "dismissed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["banner_id", "user_id"], name: "index_banner_dismissals_on_banner_id_and_user_id", unique: true
    t.index ["banner_id"], name: "index_banner_dismissals_on_banner_id"
    t.index ["user_id"], name: "index_banner_dismissals_on_user_id"
  end

  create_table "banners", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.string "banner_type", default: "info"
    t.string "icon"
    t.string "background_color"
    t.string "text_color"
    t.string "button_text"
    t.string "button_url"
    t.string "target_audience", default: "all"
    t.text "target_filters"
    t.boolean "is_dismissible", default: true
    t.boolean "is_active", default: true
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "priority", default: 0
    t.integer "views_count", default: 0
    t.integer "clicks_count", default: 0
    t.integer "dismissals_count", default: 0
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["banner_type"], name: "index_banners_on_banner_type"
    t.index ["created_by_id"], name: "index_banners_on_created_by_id"
    t.index ["is_active"], name: "index_banners_on_is_active"
    t.index ["starts_at", "ends_at"], name: "index_banners_on_starts_at_and_ends_at"
    t.index ["target_audience"], name: "index_banners_on_target_audience"
  end

  create_table "bonus_deposits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.decimal "bonus_percentage", precision: 5, scale: 2, null: false
    t.decimal "bonus_amount", precision: 15, scale: 2, null: false
    t.decimal "total_credit", precision: 15, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_bonus_deposits_on_status"
    t.index ["user_id", "created_at"], name: "index_bonus_deposits_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_bonus_deposits_on_user_id"
  end

  create_table "bonus_periods", force: :cascade do |t|
    t.decimal "bonus_percentage", precision: 5, scale: 2, null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.boolean "active", default: true, null: false
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "campaign_id"
    t.index ["active"], name: "index_bonus_periods_on_active"
    t.index ["campaign_id"], name: "index_bonus_periods_on_campaign_id"
    t.index ["end_date"], name: "index_bonus_periods_on_end_date"
    t.index ["start_date"], name: "index_bonus_periods_on_start_date"
  end

  create_table "bot_purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trading_bot_id", null: false
    t.decimal "price_paid", precision: 15, scale: 2, null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_running", default: false
    t.decimal "current_drawdown", precision: 10, scale: 2, default: "0.0"
    t.decimal "max_drawdown_recorded", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_profit", precision: 10, scale: 2, default: "0.0"
    t.integer "trades_count", default: 0
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.integer "magic_number"
    t.string "purchase_type", default: "manual"
    t.bigint "invoice_id"
    t.string "billing_status", default: "paid", null: false
    t.string "version_purchased", default: "1.0.0"
    t.boolean "has_update_pass", default: false
    t.datetime "update_pass_expires_at"
    t.index ["invoice_id"], name: "index_bot_purchases_on_invoice_id"
    t.index ["magic_number"], name: "index_bot_purchases_on_magic_number"
    t.index ["purchase_type"], name: "index_bot_purchases_on_purchase_type"
    t.index ["status"], name: "index_bot_purchases_on_status"
    t.index ["trading_bot_id"], name: "index_bot_purchases_on_trading_bot_id"
    t.index ["user_id", "trading_bot_id"], name: "index_bot_purchases_on_user_id_and_trading_bot_id"
    t.index ["user_id"], name: "index_bot_purchases_on_user_id"
  end

  create_table "bot_update_purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "bot_purchase_id", null: false
    t.bigint "bot_update_id", null: false
    t.string "purchase_type", default: "single"
    t.decimal "price_paid", precision: 10, scale: 2, null: false
    t.string "stripe_payment_intent_id"
    t.string "status", default: "pending"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bot_purchase_id"], name: "index_bot_update_purchases_on_bot_purchase_id"
    t.index ["bot_update_id"], name: "index_bot_update_purchases_on_bot_update_id"
    t.index ["status"], name: "index_bot_update_purchases_on_status"
    t.index ["user_id", "bot_update_id"], name: "index_bot_update_purchases_on_user_id_and_bot_update_id", unique: true
    t.index ["user_id"], name: "index_bot_update_purchases_on_user_id"
  end

  create_table "bot_updates", force: :cascade do |t|
    t.bigint "trading_bot_id", null: false
    t.string "version", null: false
    t.string "title", null: false
    t.text "description"
    t.text "changelog"
    t.text "highlights"
    t.boolean "is_major", default: false
    t.boolean "is_free", default: false
    t.datetime "released_at", default: -> { "CURRENT_TIMESTAMP" }
    t.boolean "notify_users", default: true
    t.integer "upgrade_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["released_at"], name: "index_bot_updates_on_released_at"
    t.index ["trading_bot_id", "version"], name: "index_bot_updates_on_trading_bot_id_and_version", unique: true
    t.index ["trading_bot_id"], name: "index_bot_updates_on_trading_bot_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.boolean "is_active", default: true
    t.string "banner_color", default: "#3b82f6"
    t.string "popup_title", null: false
    t.text "popup_message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "button_text", limit: 255
    t.string "button_url", limit: 255
    t.index ["is_active", "start_date", "end_date"], name: "index_campaigns_on_is_active_and_start_date_and_end_date"
  end

  create_table "commission_invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "invoice_id"
    t.string "reference", null: false
    t.string "period_type"
    t.date "period_start"
    t.date "period_end"
    t.decimal "total_profit", precision: 15, scale: 2, default: "0.0"
    t.decimal "commission_rate", precision: 5, scale: 2
    t.decimal "commission_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "late_fee", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 15, scale: 2, default: "0.0"
    t.string "status", default: "pending"
    t.string "stripe_payment_intent_id"
    t.datetime "due_date"
    t.datetime "paid_at"
    t.datetime "reminder_sent_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_commission_invoices_on_due_date"
    t.index ["invoice_id"], name: "index_commission_invoices_on_invoice_id"
    t.index ["reference"], name: "index_commission_invoices_on_reference", unique: true
    t.index ["status"], name: "index_commission_invoices_on_status"
    t.index ["user_id"], name: "index_commission_invoices_on_user_id"
  end

  create_table "commission_reminders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", default: "initial", null: false
    t.decimal "amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "watermark_reference", precision: 15, scale: 2, default: "0.0"
    t.string "phone_number"
    t.string "status", default: "pending", null: false
    t.datetime "deadline_at"
    t.datetime "sent_at"
    t.text "response_payload"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "message_content"
    t.string "external_id"
    t.index ["user_id", "kind", "created_at"], name: "idx_commission_reminders_user_kind_created"
    t.index ["user_id"], name: "index_commission_reminders_on_user_id"
  end

  create_table "credit_packs", force: :cascade do |t|
    t.integer "amount"
    t.integer "bonus_percentage"
    t.string "label"
    t.boolean "is_popular"
    t.boolean "is_best"
    t.boolean "active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "credits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_credits_on_created_at"
    t.index ["user_id"], name: "index_credits_on_user_id"
  end

  create_table "database_backups", force: :cascade do |t|
    t.string "filename", null: false
    t.bigint "file_size"
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.text "notes"
    t.datetime "backup_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["backup_date"], name: "index_database_backups_on_backup_date"
    t.index ["created_at"], name: "index_database_backups_on_created_at"
    t.index ["status"], name: "index_database_backups_on_status"
  end

  create_table "deposits", force: :cascade do |t|
    t.bigint "mt5_account_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "deposit_date", null: false
    t.string "transaction_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deposit_date"], name: "index_deposits_on_deposit_date"
    t.index ["mt5_account_id"], name: "index_deposits_on_mt5_account_id"
    t.index ["transaction_id"], name: "index_deposits_on_transaction_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "code", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "status", default: "pending"
    t.datetime "used_at"
    t.datetime "expires_at"
    t.text "broker_data"
    t.text "broker_credentials"
    t.text "selected_bots"
    t.integer "step", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "budget"
    t.string "stripe_payment_intent_id"
    t.index ["code"], name: "index_invitations_on_code", unique: true
    t.index ["status"], name: "index_invitations_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_invitations_on_stripe_payment_intent_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "label", null: false
    t.string "item_type"
    t.bigint "item_id"
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_price", precision: 15, scale: 2, default: "0.0"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["item_type", "item_id"], name: "index_invoice_items_on_item_type_and_item_id"
  end

  create_table "invoice_payments", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "paid_at", null: false
    t.string "payment_method"
    t.text "notes"
    t.bigint "recorded_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_payments_on_invoice_id"
    t.index ["recorded_by_id"], name: "index_invoice_payments_on_recorded_by_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "reference", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "balance_due", precision: 15, scale: 2, default: "0.0"
    t.string "source"
    t.date "due_date"
    t.boolean "vps_included", default: true
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_customer_id"
    t.string "stripe_charge_id"
    t.index ["reference"], name: "index_invoices_on_reference", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_invoices_on_stripe_payment_intent_id"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "maintenance_settings", id: :serial, force: :cascade do |t|
    t.boolean "is_enabled", default: false
    t.string "logo_url", limit: 255
    t.string "title", limit: 255
    t.text "subtitle"
    t.text "description"
    t.datetime "countdown_date", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
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
    t.decimal "initial_balance", precision: 15, scale: 2, default: "0.0"
    t.boolean "auto_calculated_initial_balance", default: false, null: false
    t.decimal "calculated_initial_balance", precision: 15, scale: 2
    t.decimal "total_deposits", precision: 15, scale: 2, default: "0.0"
    t.boolean "is_admin_account", default: false
    t.datetime "last_heartbeat_at"
    t.string "broker_name"
    t.string "broker_server"
    t.string "broker_password"
    t.decimal "watermark_at_last_billing", precision: 15, scale: 2
    t.decimal "initial_balance_snapshot", precision: 15, scale: 2
    t.index ["is_admin_account"], name: "index_mt5_accounts_on_is_admin_account"
    t.index ["mt5_id"], name: "index_mt5_accounts_on_mt5_id", unique: true
    t.index ["user_id", "mt5_id"], name: "index_mt5_accounts_on_user_id_and_mt5_id", unique: true
    t.index ["user_id"], name: "index_mt5_accounts_on_user_id"
  end

  create_table "mt5_tokens", force: :cascade do |t|
    t.string "token", null: false
    t.text "description"
    t.string "client_name"
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_mt5_tokens_on_token", unique: true
    t.index ["used_at"], name: "index_mt5_tokens_on_used_at"
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
    t.string "payment_method"
    t.text "watermark_snapshot"
    t.text "trade_defender_penalties_snapshot"
    t.decimal "manual_watermark", precision: 15, scale: 2
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "product_purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "shop_product_id", null: false
    t.decimal "price_paid", precision: 10, scale: 2, null: false
    t.string "status", default: "pending"
    t.string "stripe_payment_intent_id"
    t.string "stripe_subscription_id"
    t.datetime "expires_at"
    t.datetime "starts_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_product_id"], name: "index_product_purchases_on_shop_product_id"
    t.index ["status"], name: "index_product_purchases_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_product_purchases_on_stripe_payment_intent_id"
    t.index ["stripe_subscription_id"], name: "index_product_purchases_on_stripe_subscription_id"
    t.index ["user_id"], name: "index_product_purchases_on_user_id"
  end

  create_table "scheduled_sms", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "created_by_id"
    t.text "message", null: false
    t.string "sms_type"
    t.string "phone_number"
    t.datetime "scheduled_at", null: false
    t.string "status", default: "pending"
    t.datetime "sent_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_scheduled_sms_on_created_by_id"
    t.index ["scheduled_at"], name: "index_scheduled_sms_on_scheduled_at"
    t.index ["status"], name: "index_scheduled_sms_on_status"
    t.index ["user_id"], name: "index_scheduled_sms_on_user_id"
  end

  create_table "shop_products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "product_type", default: "subscription", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "stripe_price_id"
    t.string "stripe_product_id"
    t.text "features"
    t.string "interval", default: "year"
    t.boolean "active", default: true
    t.integer "position", default: 0
    t.string "icon", default: "fa-box"
    t.string "badge"
    t.string "badge_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_shop_products_on_active"
    t.index ["position"], name: "index_shop_products_on_position"
    t.index ["product_type"], name: "index_shop_products_on_product_type"
  end

  create_table "sms_campaign_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "sent_by_id"
    t.bigint "sms_campaign_id"
    t.string "sms_type"
    t.text "message"
    t.string "phone_number"
    t.string "status", default: "sent"
    t.datetime "sent_at"
    t.string "provider_message_id"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sent_at"], name: "index_sms_campaign_logs_on_sent_at"
    t.index ["sent_by_id"], name: "index_sms_campaign_logs_on_sent_by_id"
    t.index ["sms_campaign_id"], name: "index_sms_campaign_logs_on_sms_campaign_id"
    t.index ["sms_type"], name: "index_sms_campaign_logs_on_sms_type"
    t.index ["status"], name: "index_sms_campaign_logs_on_status"
    t.index ["user_id"], name: "index_sms_campaign_logs_on_user_id"
  end

  create_table "sms_campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.string "sms_type"
    t.text "message_template"
    t.string "status", default: "draft"
    t.string "target_audience"
    t.text "target_filters"
    t.integer "recipients_count", default: 0
    t.integer "sent_count", default: 0
    t.integer "failed_count", default: 0
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.datetime "completed_at"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "campaign_type", default: "sms"
    t.string "email_subject"
    t.text "email_body"
    t.string "channels", default: "sms"
    t.index ["campaign_type"], name: "index_sms_campaigns_on_campaign_type"
    t.index ["created_by_id"], name: "index_sms_campaigns_on_created_by_id"
    t.index ["scheduled_at"], name: "index_sms_campaigns_on_scheduled_at"
    t.index ["status"], name: "index_sms_campaigns_on_status"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_subscription_id", null: false
    t.string "stripe_customer_id", null: false
    t.string "plan", null: false
    t.string "status", default: "active"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "canceled_at"
    t.decimal "monthly_price", precision: 10, scale: 2
    t.integer "failed_payment_count", default: 0
    t.datetime "last_payment_failed_at"
    t.datetime "last_reminder_sent_at"
    t.text "cancellation_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan"], name: "index_subscriptions_on_plan"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_customer_id"], name: "index_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "support_tickets", force: :cascade do |t|
    t.bigint "user_id"
    t.string "phone_number", null: false
    t.string "status", default: "open", null: false
    t.string "ticket_number", null: false
    t.text "subject"
    t.text "description", null: false
    t.string "sms_message_id"
    t.string "created_via", default: "sms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "read_at"
    t.string "public_token"
    t.index ["created_at"], name: "index_support_tickets_on_created_at"
    t.index ["phone_number"], name: "index_support_tickets_on_phone_number"
    t.index ["public_token"], name: "index_support_tickets_on_public_token", unique: true
    t.index ["status"], name: "index_support_tickets_on_status"
    t.index ["ticket_number"], name: "index_support_tickets_on_ticket_number", unique: true
    t.index ["user_id"], name: "index_support_tickets_on_user_id"
  end

  create_table "ticket_comments", force: :cascade do |t|
    t.bigint "support_ticket_id", null: false
    t.bigint "user_id"
    t.text "content", null: false
    t.boolean "is_internal", default: false
    t.string "author_name"
    t.string "author_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_ticket_comments_on_created_at"
    t.index ["is_internal"], name: "index_ticket_comments_on_is_internal"
    t.index ["support_ticket_id"], name: "index_ticket_comments_on_support_ticket_id"
    t.index ["user_id"], name: "index_ticket_comments_on_user_id"
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
    t.string "comment"
    t.integer "magic_number"
    t.string "trade_originality", default: "unknown"
    t.boolean "is_unauthorized_manual", default: false
    t.index ["close_time"], name: "index_trades_on_close_time"
    t.index ["comment"], name: "index_trades_on_comment"
    t.index ["is_unauthorized_manual"], name: "index_trades_on_is_unauthorized_manual"
    t.index ["magic_number"], name: "index_trades_on_magic_number"
    t.index ["mt5_account_id", "trade_id"], name: "index_trades_on_mt5_account_id_and_trade_id", unique: true
    t.index ["mt5_account_id"], name: "index_trades_on_mt5_account_id"
    t.index ["open_time"], name: "index_trades_on_open_time"
    t.index ["trade_originality"], name: "index_trades_on_trade_originality"
  end

  create_table "trading_bots", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 15, scale: 2, null: false
    t.string "status", default: "active", null: false
    t.string "bot_type"
    t.json "features"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "projection_monthly_min", precision: 10, scale: 2, default: "0.0"
    t.decimal "projection_monthly_max", precision: 10, scale: 2, default: "0.0"
    t.decimal "projection_yearly", precision: 10, scale: 2, default: "0.0"
    t.decimal "win_rate", precision: 5, scale: 2, default: "0.0"
    t.decimal "max_drawdown_limit", precision: 10, scale: 2, default: "0.0"
    t.text "strategy_description"
    t.string "risk_level", default: "medium"
    t.string "image_url"
    t.boolean "is_active", default: true
    t.string "symbol"
    t.integer "magic_number_prefix"
    t.string "current_version", default: "1.0.0"
    t.decimal "update_price", precision: 10, scale: 2, default: "49.99"
    t.decimal "update_pass_yearly_price", precision: 10, scale: 2, default: "99.0"
    t.index ["status"], name: "index_trading_bots_on_status"
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
    t.string "phone"
    t.boolean "init_mt5", default: false, null: false
    t.string "stripe_customer_id"
    t.boolean "commission_billing_enabled", default: true
    t.datetime "last_commission_billing_date"
    t.decimal "last_watermark_snapshot", precision: 15, scale: 2
    t.decimal "commission_balance_due", precision: 15, scale: 2, default: "0.0"
    t.boolean "commission_payment_failed", default: false
    t.datetime "commission_payment_failed_at"
    t.boolean "bots_suspended_for_payment", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["init_mt5"], name: "index_users_on_init_mt5"
    t.index ["mt5_api_token"], name: "index_users_on_mt5_api_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
  end

  create_table "vps", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "ip_address"
    t.string "server_location"
    t.string "status", default: "ordered"
    t.decimal "monthly_price", precision: 10, scale: 2, default: "0.0"
    t.text "access_credentials"
    t.text "notes"
    t.datetime "ordered_at"
    t.datetime "configured_at"
    t.datetime "ready_at"
    t.datetime "activated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "renewal_date"
    t.bigint "invoice_id"
    t.string "billing_status", default: "paid", null: false
    t.index ["invoice_id"], name: "index_vps_on_invoice_id"
    t.index ["status"], name: "index_vps_on_status"
    t.index ["user_id"], name: "index_vps_on_user_id"
  end

  create_table "vps_offers", force: :cascade do |t|
    t.string "name"
    t.decimal "price"
    t.string "specs"
    t.text "description"
    t.boolean "is_recommended"
    t.boolean "active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "withdrawals", force: :cascade do |t|
    t.bigint "mt5_account_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "withdrawal_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.string "status", default: "completed"
    t.string "transaction_id"
    t.index ["mt5_account_id"], name: "index_withdrawals_on_mt5_account_id"
    t.index ["transaction_id"], name: "index_withdrawals_on_transaction_id"
    t.index ["withdrawal_date"], name: "index_withdrawals_on_withdrawal_date"
  end

  add_foreign_key "backtests", "trading_bots"
  add_foreign_key "banner_dismissals", "banners"
  add_foreign_key "banner_dismissals", "users"
  add_foreign_key "banners", "users", column: "created_by_id"
  add_foreign_key "bonus_deposits", "users"
  add_foreign_key "bonus_periods", "campaigns"
  add_foreign_key "bot_purchases", "invoices"
  add_foreign_key "bot_purchases", "trading_bots"
  add_foreign_key "bot_purchases", "users"
  add_foreign_key "bot_update_purchases", "bot_purchases"
  add_foreign_key "bot_update_purchases", "bot_updates"
  add_foreign_key "bot_update_purchases", "users"
  add_foreign_key "bot_updates", "trading_bots"
  add_foreign_key "commission_invoices", "invoices"
  add_foreign_key "commission_invoices", "users"
  add_foreign_key "commission_reminders", "users"
  add_foreign_key "credits", "users"
  add_foreign_key "deposits", "mt5_accounts"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_payments", "invoices"
  add_foreign_key "invoice_payments", "users", column: "recorded_by_id"
  add_foreign_key "invoices", "users"
  add_foreign_key "mt5_accounts", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "product_purchases", "shop_products"
  add_foreign_key "product_purchases", "users"
  add_foreign_key "scheduled_sms", "users"
  add_foreign_key "scheduled_sms", "users", column: "created_by_id"
  add_foreign_key "sms_campaign_logs", "sms_campaigns"
  add_foreign_key "sms_campaign_logs", "users"
  add_foreign_key "sms_campaign_logs", "users", column: "sent_by_id"
  add_foreign_key "sms_campaigns", "users", column: "created_by_id"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "support_tickets", "users"
  add_foreign_key "ticket_comments", "support_tickets"
  add_foreign_key "ticket_comments", "users"
  add_foreign_key "trades", "mt5_accounts"
  add_foreign_key "vps", "invoices"
  add_foreign_key "vps", "users"
  add_foreign_key "withdrawals", "mt5_accounts"
end
