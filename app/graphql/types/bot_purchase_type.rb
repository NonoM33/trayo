module Types
  class BotPurchaseType < Types::BaseObject
    description "Bot Purchase type"

    field :id, ID, null: false
    field :price_paid, Float, null: false
    field :status, String, null: false
    field :is_running, Boolean, null: false
    field :magic_number, Integer, null: true
    field :total_profit, Float, null: true
    field :trades_count, Integer, null: true
    field :current_drawdown, Float, null: true
    field :max_drawdown_recorded, Float, null: true
    field :started_at, Types::DateTimeType, null: true
    field :stopped_at, Types::DateTimeType, null: true
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :user, Types::UserType, null: false
    field :trading_bot, Types::TradingBotType, null: false

    field :roi_percentage, Float, null: false
    field :days_active, Integer, null: false
    field :average_daily_profit, Float, null: false
    field :is_profitable, Boolean, null: false
    field :within_drawdown_limit, Boolean, null: false
    field :status_badge, String, null: false
    field :status_color, String, null: false

    def roi_percentage
      object.roi_percentage
    end

    def days_active
      object.days_active
    end

    def average_daily_profit
      object.average_daily_profit
    end

    def is_profitable
      object.is_profitable?
    end

    def within_drawdown_limit
      object.within_drawdown_limit?
    end

    def status_badge
      object.status_badge
    end

    def status_color
      object.status_color
    end
  end
end

