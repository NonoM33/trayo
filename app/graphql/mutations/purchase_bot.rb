module Mutations
  class PurchaseBot < BaseMutation
    description "Purchase a trading bot"

    argument :bot_id, ID, required: true

    field :bot_purchase, Types::BotPurchaseType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(bot_id:)
      user = context[:current_user]
      return { bot_purchase: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless user

      bot = TradingBot.find_by(id: bot_id)
      return { bot_purchase: nil, errors: [{ field: "bot_id", message: "Bot not found" }] } unless bot
      return { bot_purchase: nil, errors: [{ field: "bot_id", message: "Bot is not active" }] } unless bot.status == 'active'

      existing_purchase = user.bot_purchases.find_by(trading_bot: bot, status: 'active')
      return { bot_purchase: existing_purchase, errors: nil } if existing_purchase

      purchase = user.bot_purchases.build(
        trading_bot: bot,
        price_paid: bot.price,
        status: 'active',
        is_running: false
      )

      if purchase.save
        {
          bot_purchase: purchase,
          errors: nil
        }
      else
        {
          bot_purchase: nil,
          errors: purchase.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

