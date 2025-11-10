module Subscriptions
  class TradeUpdated < BaseSubscription
    description "Subscribe to trade updates"

    argument :user_id, ID, required: false

    field :trade, Types::TradeType, null: false

    def subscribe(user_id: nil)
      current_user = context[:current_user]
      return {} unless current_user

      user_id ||= current_user.id
      return {} unless current_user.id.to_s == user_id.to_s || current_user.is_admin?

      { user_id: user_id }
    end

    def update
      trade = object
      current_user = context[:current_user]

      return nil unless current_user
      return nil unless trade.mt5_account.user_id == current_user.id || current_user.is_admin?

      {
        trade: trade
      }
    end
  end
end

