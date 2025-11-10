class BotChannel < ApplicationCable::Channel
  def subscribed
    stream_from "bot_channel_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.broadcast_status_change(purchase)
    user = purchase.user
    ActionCable.server.broadcast(
      "bot_channel_#{user.id}",
      {
        type: 'bot_status_changed',
        bot_purchase: {
          id: purchase.id,
          status: purchase.status,
          is_running: purchase.is_running,
          total_profit: purchase.total_profit,
          current_drawdown: purchase.current_drawdown,
          roi_percentage: purchase.roi_percentage,
          started_at: purchase.started_at,
          stopped_at: purchase.stopped_at
        },
        trading_bot: {
          id: purchase.trading_bot.id,
          name: purchase.trading_bot.name
        }
      }
    )
  end
end

