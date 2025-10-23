class AddMarketingFieldsToTradingBots < ActiveRecord::Migration[8.0]
  def change
    add_column :trading_bots, :projection_monthly_min, :decimal, precision: 10, scale: 2, default: 0 unless column_exists?(:trading_bots, :projection_monthly_min)
    add_column :trading_bots, :projection_monthly_max, :decimal, precision: 10, scale: 2, default: 0 unless column_exists?(:trading_bots, :projection_monthly_max)
    add_column :trading_bots, :projection_yearly, :decimal, precision: 10, scale: 2, default: 0 unless column_exists?(:trading_bots, :projection_yearly)
    add_column :trading_bots, :win_rate, :decimal, precision: 5, scale: 2, default: 0 unless column_exists?(:trading_bots, :win_rate)
    add_column :trading_bots, :max_drawdown_limit, :decimal, precision: 10, scale: 2, default: 0 unless column_exists?(:trading_bots, :max_drawdown_limit)
    add_column :trading_bots, :strategy_description, :text unless column_exists?(:trading_bots, :strategy_description)
    add_column :trading_bots, :risk_level, :string, default: 'medium' unless column_exists?(:trading_bots, :risk_level)
    add_column :trading_bots, :image_url, :string unless column_exists?(:trading_bots, :image_url)
    add_column :trading_bots, :is_active, :boolean, default: true unless column_exists?(:trading_bots, :is_active)
  end
end

