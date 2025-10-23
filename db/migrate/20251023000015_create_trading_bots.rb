class CreateTradingBots < ActiveRecord::Migration[8.0]
  def change
    create_table :trading_bots do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 15, scale: 2, null: false
      t.string :status, default: "active", null: false
      t.string :bot_type
      t.json :features
      t.timestamps
      
      t.index :status
    end
    
    create_table :bot_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trading_bot, null: false, foreign_key: true
      t.decimal :price_paid, precision: 15, scale: 2, null: false
      t.string :status, default: "active", null: false
      t.timestamps
      
      t.index [:user_id, :trading_bot_id]
      t.index :status
    end
  end
end
