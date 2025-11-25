module Api
  module V2
    class BacktestsController < BaseController
      before_action :set_bot, only: [:index, :create]
      before_action :set_backtest, only: [:show]

      def index
        backtests = @bot.backtests
        backtests = apply_filters(backtests, allowed_filters: {
          is_active: {},
          total_profit: { gt: true, lt: true, gte: true, lte: true },
          win_rate: { gt: true, lt: true, gte: true, lte: true }
        })

        if params[:start_date].present?
          backtests = backtests.where("start_date >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          backtests = backtests.where("end_date <= ?", Time.parse(params[:end_date]))
        end

        paginated = paginate_with_cursor(backtests, cursor_field: :created_at)

        render_success({
          data: paginated[:data].map { |b| backtest_serializer(b) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ backtest: backtest_serializer(@backtest) })
      end

      private

      def set_bot
        @bot = TradingBot.find_by(id: params[:bot_id])
        render_error("Bot not found", status: :not_found) unless @bot
      end

      def set_backtest
        @backtest = Backtest.find_by(id: params[:id], trading_bot_id: params[:bot_id])
        render_error("Backtest not found", status: :not_found) unless @backtest
      end

      def backtest_serializer(backtest)
        {
          id: backtest.id,
          trading_bot_id: backtest.trading_bot_id,
          start_date: backtest.start_date,
          end_date: backtest.end_date,
          duration_days: backtest.duration_days,
          duration_years: backtest.duration_years,
          total_trades: backtest.total_trades,
          winning_trades: backtest.winning_trades,
          losing_trades: backtest.losing_trades,
          total_profit: backtest.total_profit,
          max_drawdown: backtest.max_drawdown,
          win_rate: backtest.win_rate,
          projection_monthly_min: backtest.projection_monthly_min,
          projection_monthly_max: backtest.projection_monthly_max,
          projection_yearly: backtest.projection_yearly,
          is_active: backtest.is_active,
          created_at: backtest.created_at,
          updated_at: backtest.updated_at
        }
      end
    end
  end
end

