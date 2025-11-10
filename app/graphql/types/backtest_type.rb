module Types
  class BacktestType < Types::BaseObject
    description "Backtest type"

    field :id, ID, null: false
    field :projection_monthly_min, Float, null: true
    field :projection_monthly_max, Float, null: true
    field :projection_yearly, Float, null: true
    field :max_drawdown, Float, null: true
    field :win_rate, Float, null: true
    field :status, String, null: false
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :trading_bot, Types::TradingBotType, null: false
  end
end

