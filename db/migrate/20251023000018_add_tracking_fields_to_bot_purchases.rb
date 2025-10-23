class AddTrackingFieldsToBotPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :bot_purchases, :is_running, :boolean, default: false
    add_column :bot_purchases, :current_drawdown, :decimal, precision: 10, scale: 2, default: 0
    add_column :bot_purchases, :max_drawdown_recorded, :decimal, precision: 10, scale: 2, default: 0
    add_column :bot_purchases, :total_profit, :decimal, precision: 10, scale: 2, default: 0
    add_column :bot_purchases, :trades_count, :integer, default: 0
    add_column :bot_purchases, :started_at, :datetime
    add_column :bot_purchases, :stopped_at, :datetime
  end
end

