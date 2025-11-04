module Mutations
  class UpdateMt5Account < BaseMutation
    description "Update MT5 account (admin only)"

    argument :id, ID, required: true
    argument :account_name, String, required: false
    argument :balance, Float, required: false
    argument :initial_balance, Float, required: false
    argument :high_watermark, Float, required: false

    field :mt5_account, Types::Mt5AccountType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(id:, account_name: nil, balance: nil, initial_balance: nil, high_watermark: nil)
      user = context[:current_user]
      return { mt5_account: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless user&.is_admin?

      account = Mt5Account.find_by(id: id)
      return { mt5_account: nil, errors: [{ field: "id", message: "Account not found" }] } unless account

      account.account_name = account_name if account_name.present?
      account.balance = balance if balance.present?
      account.initial_balance = initial_balance if initial_balance.present?
      account.high_watermark = high_watermark if high_watermark.present?

      if account.save
        {
          mt5_account: account,
          errors: nil
        }
      else
        {
          mt5_account: nil,
          errors: account.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

