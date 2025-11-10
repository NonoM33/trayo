module Types
  class StatsType < Types::BaseObject
    description "Statistics type"

    field :total_profit, Float, null: false
    field :total_trades, Integer, null: false
    field :winning_trades, Integer, null: false
    field :losing_trades, Integer, null: false
    field :win_rate, Float, null: false
    field :average_profit, Float, null: false
    field :best_trade, Float, null: true
    field :worst_trade, Float, null: true
    field :total_commission, Float, null: false
    field :total_swap, Float, null: false
  end
end

