module Types
  class WithdrawalType < Types::BaseObject
    description "Withdrawal type"

    field :id, ID, null: false
    field :amount, Float, null: false
    field :withdrawal_date, Types::DateTimeType, null: true
    field :transaction_id, String, null: true
    field :notes, String, null: true
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :mt5_account, Types::Mt5AccountType, null: false
  end
end

