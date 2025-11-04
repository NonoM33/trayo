module Mutations
  class UpdateBotPerformance < BaseMutation
    description "Update bot performance (for MT5 script)"

    argument :purchase_id, ID, required: true
    argument :profit, Float, required: true
    argument :drawdown, Float, required: false, default_value: 0

    field :bot_purchase, Types::BotPurchaseType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(purchase_id:, profit:, drawdown: 0)
      user = context[:current_user]
      return { bot_purchase: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless user

      purchase = user.bot_purchases.find_by(id: purchase_id)
      return { bot_purchase: nil, errors: [{ field: "purchase_id", message: "Bot purchase not found" }] } unless purchase

      purchase.update_performance(profit, drawdown)

      {
        bot_purchase: purchase.reload,
        errors: nil
      }
    end
  end
end

