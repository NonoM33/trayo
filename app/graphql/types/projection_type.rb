module Types
  class ProjectionType < Types::BaseObject
    description "Projection type"

    field :account_id, ID, null: false
    field :mt5_id, String, null: false
    field :account_name, String, null: false
    field :current_balance, Float, null: false
    field :projected_balance, Float, null: false
    field :daily_average, Float, null: false
    field :projected_profit, Float, null: false
    field :confidence, String, null: false
    field :based_on_days, Integer, null: false
  end
end

