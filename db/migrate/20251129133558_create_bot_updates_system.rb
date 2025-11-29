class CreateBotUpdatesSystem < ActiveRecord::Migration[8.0]
  def change
    add_column :trading_bots, :current_version, :string, default: "1.0.0"
    add_column :trading_bots, :update_price, :decimal, precision: 10, scale: 2, default: 49.99
    add_column :trading_bots, :update_pass_yearly_price, :decimal, precision: 10, scale: 2, default: 99.00
    
    add_column :bot_purchases, :version_purchased, :string, default: "1.0.0"
    add_column :bot_purchases, :has_update_pass, :boolean, default: false
    add_column :bot_purchases, :update_pass_expires_at, :datetime

    create_table :bot_updates do |t|
      t.references :trading_bot, null: false, foreign_key: true
      t.string :version, null: false
      t.string :title, null: false
      t.text :description
      t.text :changelog
      t.text :highlights
      t.boolean :is_major, default: false
      t.boolean :is_free, default: false
      t.datetime :released_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.boolean :notify_users, default: true
      t.integer :upgrade_count, default: 0

      t.timestamps
    end

    add_index :bot_updates, [:trading_bot_id, :version], unique: true
    add_index :bot_updates, :released_at

    create_table :bot_update_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :bot_purchase, null: false, foreign_key: true
      t.references :bot_update, null: false, foreign_key: true
      t.string :purchase_type, default: "single"
      t.decimal :price_paid, precision: 10, scale: 2, null: false
      t.string :stripe_payment_intent_id
      t.string :status, default: "pending"
      t.datetime :paid_at

      t.timestamps
    end

    add_index :bot_update_purchases, [:user_id, :bot_update_id], unique: true
    add_index :bot_update_purchases, :status
  end
end
