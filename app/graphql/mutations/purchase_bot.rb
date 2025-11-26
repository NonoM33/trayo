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

      existing_paid = user.bot_purchases.find_by(trading_bot: bot, billing_status: 'paid')
      return { bot_purchase: existing_paid, errors: nil } if existing_paid

      if user.bot_purchases.exists?(trading_bot: bot, billing_status: %w[pending partial])
        return {
          bot_purchase: nil,
          errors: [{ field: "bot_id", message: "Facture déjà en attente pour ce bot" }]
        }
      end

      purchase = nil
      ActiveRecord::Base.transaction do
        purchase = user.bot_purchases.create!(
          trading_bot: bot,
          price_paid: bot.price,
          status: 'active',
          is_running: false
        )

        Invoices::Builder.new(
          user: user,
          source: "shop",
          metadata: { bot_id: bot.id },
          deactivate_bots: true
        ).build_from_selection(
          bot_purchases: [purchase],
          vps_list: []
        )
      end

      {
        bot_purchase: purchase,
        errors: nil
      }
    rescue ActiveRecord::RecordInvalid => e
      {
        bot_purchase: nil,
        errors: [{ field: "base", message: e.message }]
      }
    end
  end
end

