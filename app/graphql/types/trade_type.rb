module Types
  class TradeType < Types::BaseObject
    description "Trade type"

    field :id, ID, null: false
    field :trade_id, String, null: false
    field :symbol, String, null: false
    field :trade_type, String, null: false
    field :volume, Float, null: false
    field :open_price, Float, null: true
    field :close_price, Float, null: true
    field :profit, Float, null: false
    field :commission, Float, null: true
    field :swap, Float, null: true
    field :open_time, Types::DateTimeType, null: true
    field :close_time, Types::DateTimeType, null: true
    field :status, String, null: false
    field :magic_number, Integer, null: true
    field :comment, String, null: true
    field :trade_originality, String, null: true
    field :is_unauthorized_manual, Boolean, null: false
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :mt5_account, Types::Mt5AccountType, null: false
    field :bot_name, String, null: true
    field :gross_profit, Float, null: false
    field :net_profit, Float, null: false
    field :total_costs, Float, null: false

    def bot_name
      object.bot_name
    end

    def gross_profit
      object.gross_profit
    end

    def net_profit
      object.net_profit
    end

    def total_costs
      object.total_costs
    end
  end
end

