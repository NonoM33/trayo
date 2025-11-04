require 'csv'

module Api
  module V2
    class TradesController < BaseController
      before_action :set_trade, only: [:show]

      def index
        trades = current_user.trades
        trades = apply_filters(trades, allowed_filters: {
          symbol: {},
          trade_type: {},
          status: {},
          profit: { gt: true, lt: true, gte: true, lte: true },
          account_id: {},
          bot_id: {}
        })
        trades = apply_search(trades, search_fields: ['symbol', 'trade_id', 'comment'])

        if params[:start_date].present?
          trades = trades.where("close_time >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          trades = trades.where("close_time <= ?", Time.parse(params[:end_date]))
        end

        if params[:bot_id].present?
          bot = TradingBot.find_by(id: params[:bot_id])
          trades = trades.where(magic_number: bot.magic_number_prefix) if bot&.magic_number_prefix
        end

        paginated = paginate_with_cursor(trades, cursor_field: :close_time)

        render_success({
          data: paginated[:data].map { |t| trade_serializer(t) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ trade: trade_serializer(@trade) })
      end

      def stats
        trades = current_user.trades.closed

        if params[:account_id].present?
          trades = trades.where(mt5_account_id: params[:account_id])
        end

        if params[:bot_id].present?
          bot = TradingBot.find_by(id: params[:bot_id])
          trades = trades.where(magic_number: bot.magic_number_prefix) if bot&.magic_number_prefix
        end

        if params[:start_date].present?
          trades = trades.where("close_time >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          trades = trades.where("close_time <= ?", Time.parse(params[:end_date]))
        end

        trades_array = trades.to_a
        winning_trades = trades_array.select { |t| t.profit > 0 }
        losing_trades = trades_array.select { |t| t.profit < 0 }

        render_success({
          total_profit: trades_array.sum(&:profit).round(2),
          total_trades: trades_array.count,
          winning_trades: winning_trades.count,
          losing_trades: losing_trades.count,
          win_rate: trades_array.any? ? (winning_trades.count.to_f / trades_array.count * 100).round(2) : 0,
          average_profit: trades_array.any? ? (trades_array.sum(&:profit) / trades_array.count).round(2) : 0,
          best_trade: trades_array.any? ? trades_array.max_by(&:profit)&.profit : nil,
          worst_trade: trades_array.any? ? trades_array.min_by(&:profit)&.profit : nil,
          total_commission: trades_array.sum { |t| t.commission || 0 }.round(2),
          total_swap: trades_array.sum { |t| t.swap || 0 }.round(2)
        })
      end

      def export
        trades = current_user.trades.closed

        if params[:account_id].present?
          trades = trades.where(mt5_account_id: params[:account_id])
        end
        if params[:start_date].present?
          trades = trades.where("close_time >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          trades = trades.where("close_time <= ?", Time.parse(params[:end_date]))
        end

        format = params[:format] || 'csv'
        csv_data = CSV.generate(headers: true) do |csv|
          csv << ['ID', 'Trade ID', 'Symbol', 'Type', 'Volume', 'Open Price', 'Close Price', 
                  'Profit', 'Commission', 'Swap', 'Open Time', 'Close Time', 'Status', 'Bot Name']
          trades.each do |trade|
            csv << [
              trade.id,
              trade.trade_id,
              trade.symbol,
              trade.trade_type,
              trade.volume,
              trade.open_price,
              trade.close_price,
              trade.profit,
              trade.commission,
              trade.swap,
              trade.open_time,
              trade.close_time,
              trade.status,
              trade.bot_name
            ]
          end
        end

        send_data csv_data, filename: "trades_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv", 
                  type: 'text/csv', disposition: 'attachment'
      end

      private

      def set_trade
        @trade = current_user.trades.find_by(id: params[:id])
        render_error("Trade not found", status: :not_found) unless @trade
      end

      def trade_serializer(trade)
        {
          id: trade.id,
          trade_id: trade.trade_id,
          symbol: trade.symbol,
          trade_type: trade.trade_type,
          volume: trade.volume,
          open_price: trade.open_price,
          close_price: trade.close_price,
          profit: trade.profit,
          commission: trade.commission,
          swap: trade.swap,
          open_time: trade.open_time,
          close_time: trade.close_time,
          status: trade.status,
          magic_number: trade.magic_number,
          bot_name: trade.bot_name,
          gross_profit: trade.gross_profit,
          net_profit: trade.net_profit,
          total_costs: trade.total_costs,
          mt5_account: {
            id: trade.mt5_account.id,
            mt5_id: trade.mt5_account.mt5_id,
            account_name: trade.mt5_account.account_name
          }
        }
      end
    end
  end
end

