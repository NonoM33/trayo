module Types
  class UserType < Types::BaseObject
    description "User type"

    field :id, ID, null: false
    field :email, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :mt5_api_token, String, null: true
    field :commission_rate, Float, null: false
    field :is_admin, Boolean, null: false
    field :init_mt5, Boolean, null: false
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :mt5_accounts, [Types::Mt5AccountType], null: true
    field :bot_purchases, [Types::BotPurchaseType], null: true
    field :vps, [Types::VpsType], null: true
    field :payments, [Types::PaymentType], null: true
    field :credits, [Types::CreditType], null: true

    def mt5_api_token
      return nil unless object.mt5_api_token.present?
      return nil unless context[:current_user]&.id == object.id
      object.mt5_api_token
    end
  end
end

