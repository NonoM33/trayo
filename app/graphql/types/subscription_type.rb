module Types
  class SubscriptionType < Types::BaseObject
    field :trade_created, subscription: Subscriptions::TradeCreated
    field :trade_updated, subscription: Subscriptions::TradeUpdated
    field :account_balance_updated, subscription: Subscriptions::AccountBalanceUpdated
    field :bot_status_changed, subscription: Subscriptions::BotStatusChanged
    field :payment_created, subscription: Subscriptions::PaymentCreated
  end
end

