class TradeChannel < ApplicationCable::Channel
  def subscribed
    stream_from "trade_channel_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.broadcast_created(trade)
    user = trade.mt5_account.user
    ActionCable.server.broadcast(
      "trade_channel_#{user.id}",
      {
        type: 'trade_created',
        trade: {
          id: trade.id,
          trade_id: trade.trade_id,
          symbol: trade.symbol,
          trade_type: trade.trade_type,
          volume: trade.volume,
          profit: trade.profit,
          open_time: trade.open_time,
          close_time: trade.close_time,
          status: trade.status,
          bot_name: trade.bot_name
        }
      }
    )
  end

  def self.broadcast_updated(trade)
    user = trade.mt5_account.user
    ActionCable.server.broadcast(
      "trade_channel_#{user.id}",
      {
        type: 'trade_updated',
        trade: {
          id: trade.id,
          trade_id: trade.trade_id,
          symbol: trade.symbol,
          trade_type: trade.trade_type,
          volume: trade.volume,
          profit: trade.profit,
          open_time: trade.open_time,
          close_time: trade.close_time,
          status: trade.status,
          bot_name: trade.bot_name
        }
      }
    )
  end
end

