module Api
  module V2
    class StatsController < BaseController
      def dashboard
        user = current_user
        render_success({
          total_balance: user.mt5_accounts.sum(:balance).round(2),
          total_profits: user.total_profits.round(2),
          total_commission_due: user.total_commission_due.round(2),
          total_credits: user.total_credits.round(2),
          balance_due: user.balance_due.round(2),
          accounts_count: user.mt5_accounts.count,
          bots_count: user.bot_purchases.count,
          active_bots_count: user.bot_purchases.where(status: 'active').count,
          recent_trades_count: user.trades.where("close_time >= ?", 24.hours.ago).count,
          average_daily_gain: user.average_daily_gain
        })
      end

      def profits
        user = current_user
        period = params[:period] || '30_days'

        date_range = case period
        when "7_days" then 7.days.ago..Time.current
        when "30_days" then 30.days.ago..Time.current
        when "3_months" then 3.months.ago..Time.current
        when "6_months" then 6.months.ago..Time.current
        when "1_year" then 1.year.ago..Time.current
        else 30.days.ago..Time.current
        end

        trades = user.trades.where(close_time: date_range)
        trades = trades.where(mt5_account_id: params[:account_id]) if params[:account_id].present?

        if params[:bot_id].present?
          bot = TradingBot.find_by(id: params[:bot_id])
          trades = trades.where(magic_number: bot.magic_number_prefix) if bot&.magic_number_prefix
        end

        trades_array = trades.to_a

        render_success({
          period: period,
          total_profit: trades_array.sum(&:profit).round(2),
          total_trades: trades_array.count,
          average_daily_profit: trades_array.any? ? (trades_array.sum(&:profit) / (date_range.count / 1.0)).round(2) : 0,
          monthly_average: trades_array.any? ? (trades_array.sum(&:profit) / (date_range.count / 30.0)).round(2) : 0
        })
      end

      def trades
        user = current_user
        period = params[:period] || '30_days'

        date_range = case period
        when "7_days" then 7.days.ago..Time.current
        when "30_days" then 30.days.ago..Time.current
        when "3_months" then 3.months.ago..Time.current
        when "6_months" then 6.months.ago..Time.current
        when "1_year" then 1.year.ago..Time.current
        else 30.days.ago..Time.current
        end

        trades = user.trades.where(close_time: date_range)
        trades = trades.where(mt5_account_id: params[:account_id]) if params[:account_id].present?

        if params[:bot_id].present?
          bot = TradingBot.find_by(id: params[:bot_id])
          trades = trades.where(magic_number: bot.magic_number_prefix) if bot&.magic_number_prefix
        end

        trades_array = trades.to_a
        winning_trades = trades_array.select { |t| t.profit > 0 }
        losing_trades = trades_array.select { |t| t.profit < 0 }

        render_success({
          period: period,
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
    end
  end
end

