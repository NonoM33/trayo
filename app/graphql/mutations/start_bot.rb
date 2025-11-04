module Mutations
  class StartBot < BaseMutation
    description "Start a bot"

    argument :purchase_id, ID, required: true

    field :bot_purchase, Types::BotPurchaseType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(purchase_id:)
      user = context[:current_user]
      return { bot_purchase: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless user

      purchase = user.bot_purchases.find_by(id: purchase_id)
      return { bot_purchase: nil, errors: [{ field: "purchase_id", message: "Bot purchase not found" }] } unless purchase

      purchase.start!

      {
        bot_purchase: purchase,
        errors: nil
      }
    end
  end
end

