module Api
  module V2
    class AccountsController < BaseController
      before_action :set_account, only: [:show, :balance, :trades, :projection, :stats]

      def index
        accounts = current_user.mt5_accounts
        accounts = apply_filters(accounts, allowed_filters: {
          broker_name: {},
          mt5_id: {},
          account_name: { like: true }
        })
        accounts = apply_search(accounts, search_fields: ['account_name', 'mt5_id', 'broker_name'])

        paginated = paginate_with_cursor(accounts, cursor_field: :id)
        
        render_success({
          data: paginated[:data].map { |a| account_serializer(a) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ account: account_serializer(@account) })
      end

      def balance
        render_success({
          account_id: @account.id,
          mt5_id: @account.mt5_id,
          account_name: @account.account_name,
          balance: @account.balance,
          equity: @account.equity,
          initial_balance: @account.initial_balance,
          high_watermark: @account.high_watermark,
          total_withdrawals: @account.total_withdrawals,
          total_deposits: @account.total_deposits,
          net_gains: @account.net_gains,
          real_gains: @account.real_gains,
          commissionable_gains: @account.commissionable_gains
        })
      end

      def trades
        trades = @account.trades
        trades = apply_filters(trades, allowed_filters: {
          symbol: {},
          trade_type: {},
          status: {},
          profit: { gt: true, lt: true, gte: true, lte: true },
          bot_id: {}
        })
        trades = apply_search(trades, search_fields: ['symbol', 'trade_id', 'comment'])

        if params[:start_date].present?
          trades = trades.where("close_time >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          trades = trades.where("close_time <= ?", Time.parse(params[:end_date]))
        end

        paginated = paginate_with_cursor(trades, cursor_field: :close_time)

        render_success({
          data: paginated[:data].map { |t| trade_serializer(t) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def projection
        days = params[:days]&.to_i || 30
        projection_data = @account.calculate_projection(days)
        
        render_success({
          account_id: @account.id,
          mt5_id: @account.mt5_id,
          account_name: @account.account_name,
          current_balance: @account.balance,
          projected_balance: projection_data[:projected_balance],
          daily_average: projection_data[:daily_average],
          projected_profit: projection_data[:projected_profit],
          confidence: projection_data[:confidence],
          based_on_days: days
        })
      end

      def stats
        trades = @account.trades.closed
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

      private

      def set_account
        @account = current_user.mt5_accounts.find_by(id: params[:id])
        render_error("Account not found", status: :not_found) unless @account
      end

      def account_serializer(account)
        {
          id: account.id,
          mt5_id: account.mt5_id,
          account_name: account.account_name,
          balance: account.balance,
          equity: account.equity,
          initial_balance: account.initial_balance,
          high_watermark: account.high_watermark,
          total_withdrawals: account.total_withdrawals,
          total_deposits: account.total_deposits,
          broker_name: account.broker_name,
          broker_server: account.broker_server,
          last_sync_at: account.last_sync_at,
          created_at: account.created_at,
          updated_at: account.updated_at
        }
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
          total_costs: trade.total_costs
        }
      end
    end
  end
end

