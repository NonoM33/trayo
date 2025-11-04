module Types
  class TradingBotType < Types::BaseObject
    description "Trading Bot type"

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :price, Float, null: false
    field :status, String, null: false
    field :is_active, Boolean, null: false
    field :risk_level, String, null: true
    field :magic_number_prefix, Integer, null: true
    field :max_drawdown_limit, Float, null: true
    field :projection_monthly_min, Float, null: true
    field :projection_monthly_max, Float, null: true
    field :projection_yearly, Float, null: true
    field :win_rate, Float, null: true
    field :features, GraphQL::Types::JSON, null: true
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :bot_purchases, [Types::BotPurchaseType], null: true
    field :backtests, [Types::BacktestType], null: true

    field :projected_monthly_average, Float, null: false
    field :risk_badge_color, String, null: false
    field :risk_label, String, null: false

    def projected_monthly_average
      object.projected_monthly_average
    end

    def risk_badge_color
      object.risk_badge_color
    end

    def risk_label
      object.risk_label
    end
  end
end

