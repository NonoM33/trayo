class AccountChannel < ApplicationCable::Channel
  def subscribed
    stream_from "account_channel_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.broadcast_update(account)
    user = account.user
    ActionCable.server.broadcast(
      "account_channel_#{user.id}",
      {
        type: 'account_balance_updated',
        account: {
          id: account.id,
          mt5_id: account.mt5_id,
          account_name: account.account_name,
          balance: account.balance,
          equity: account.equity,
          net_gains: account.net_gains,
          real_gains: account.real_gains,
          commissionable_gains: account.commissionable_gains,
          updated_at: account.updated_at
        }
      }
    )
  end
end

