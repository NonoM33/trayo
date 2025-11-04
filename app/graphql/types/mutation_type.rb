# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :register_user, mutation: Mutations::RegisterUser
    field :login_user, mutation: Mutations::LoginUser
    field :update_profile, mutation: Mutations::UpdateProfile
    field :update_password, mutation: Mutations::UpdatePassword
    field :purchase_bot, mutation: Mutations::PurchaseBot
    field :start_bot, mutation: Mutations::StartBot
    field :stop_bot, mutation: Mutations::StopBot
    field :update_bot_performance, mutation: Mutations::UpdateBotPerformance
    field :create_payment, mutation: Mutations::CreatePayment
    field :update_mt5_account, mutation: Mutations::UpdateMt5Account
    field :create_credit, mutation: Mutations::CreateCredit
    field :update_vps_status, mutation: Mutations::UpdateVpsStatus
  end
end
