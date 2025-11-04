module Subscriptions
  class AccountBalanceUpdated < BaseSubscription
    description "Subscribe to account balance updates"

    argument :account_id, ID, required: false

    field :mt5_account, Types::Mt5AccountType, null: false

    def subscribe(account_id: nil)
      current_user = context[:current_user]
      return {} unless current_user

      if account_id.present?
        account = Mt5Account.find_by(id: account_id)
        return {} unless account
        return {} unless account.user_id == current_user.id || current_user.is_admin?
      end

      { user_id: current_user.id, account_id: account_id }
    end

    def update
      account = object
      current_user = context[:current_user]

      return nil unless current_user
      return nil unless account.user_id == current_user.id || current_user.is_admin?

      {
        mt5_account: account
      }
    end
  end
end

