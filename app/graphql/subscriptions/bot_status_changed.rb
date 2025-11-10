module Subscriptions
  class BotStatusChanged < BaseSubscription
    description "Subscribe to bot status changes"

    argument :purchase_id, ID, required: false

    field :bot_purchase, Types::BotPurchaseType, null: false

    def subscribe(purchase_id: nil)
      current_user = context[:current_user]
      return {} unless current_user

      if purchase_id.present?
        purchase = BotPurchase.find_by(id: purchase_id)
        return {} unless purchase
        return {} unless purchase.user_id == current_user.id || current_user.is_admin?
      end

      { user_id: current_user.id, purchase_id: purchase_id }
    end

    def update
      purchase = object
      current_user = context[:current_user]

      return nil unless current_user
      return nil unless purchase.user_id == current_user.id || current_user.is_admin?

      {
        bot_purchase: purchase
      }
    end
  end
end

