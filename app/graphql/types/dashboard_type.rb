module Types
  class DashboardType < Types::BaseObject
    description "Dashboard aggregation type"

    field :total_balance, Float, null: false
    field :total_profits, Float, null: false
    field :total_commission_due, Float, null: false
    field :total_credits, Float, null: false
    field :balance_due, Float, null: false
    field :accounts_count, Integer, null: false
    field :bots_count, Integer, null: false
    field :active_bots_count, Integer, null: false
    field :recent_trades_count, Integer, null: false
    field :average_daily_gain, Float, null: false
  end
end

