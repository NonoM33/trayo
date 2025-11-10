module Types
  class Mt5AccountType < Types::BaseObject
    description "MT5 Account type"

    field :id, ID, null: false
    field :mt5_id, String, null: false
    field :account_name, String, null: false
    field :balance, Float, null: false
    field :equity, Float, null: true
    field :initial_balance, Float, null: true
    field :calculated_initial_balance, Float, null: true
    field :high_watermark, Float, null: true
    field :total_withdrawals, Float, null: true
    field :total_deposits, Float, null: true
    field :broker_name, String, null: true
    field :broker_server, String, null: true
    field :last_sync_at, Types::DateTimeType, null: true
    field :last_heartbeat_at, Types::DateTimeType, null: true
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :user, Types::UserType, null: false
    field :trades, Types::TradeType.connection_type, null: true
    field :withdrawals, [Types::WithdrawalType], null: true
    field :deposits, [Types::DepositType], null: true

    field :net_gains, Float, null: false
    field :real_gains, Float, null: false
    field :commissionable_gains, Float, null: false

    def net_gains
      object.net_gains
    end

    def real_gains
      object.real_gains
    end

    def commissionable_gains
      object.commissionable_gains
    end
  end
end

