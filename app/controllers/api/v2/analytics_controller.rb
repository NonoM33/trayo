module Api
  module V2
    class AnalyticsController < BaseController
      def account_performance
        account = current_user.mt5_accounts.find_by(id: params[:account_id])
        return render_error("Account not found", status: :not_found) unless account

        period = params[:period] || '30_days'
        date_range = get_date_range(period)

        trades = account.trades.where(close_time: date_range).closed
        trades_array = trades.to_a

        daily_profits = trades_array.group_by { |t| t.close_time.to_date }
          .map { |date, day_trades| { date: date, profit: day_trades.sum(&:profit) } }
          .sort_by { |d| d[:date] }

        monthly_profits = trades_array.group_by { |t| "#{t.close_time.year}-#{t.close_time.month}" }
          .map { |month, month_trades| { month: month, profit: month_trades.sum(&:profit) } }
          .sort_by { |m| m[:month] }

        render_success({
          account_id: account.id,
          period: period,
          total_profit: trades_array.sum(&:profit).round(2),
          total_trades: trades_array.count,
          daily_profits: daily_profits,
          monthly_profits: monthly_profits,
          average_daily_profit: trades_array.any? ? (trades_array.sum(&:profit) / date_range.count).round(2) : 0
        })
      end

      def bot_performance
        purchase = current_user.bot_purchases.find_by(id: params[:bot_purchase_id])
        return render_error("Bot purchase not found", status: :not_found) unless purchase

        period = params[:period] || '30_days'
        date_range = get_date_range(period)

        trades = purchase.associated_trades.where(close_time: date_range).closed
        trades_array = trades.to_a

        daily_profits = trades_array.group_by { |t| t.close_time.to_date }
          .map { |date, day_trades| { date: date, profit: day_trades.sum(&:profit) } }
          .sort_by { |d| d[:date] }

        by_day_of_week = purchase.analyze_by_day_of_week
        by_hour = purchase.analyze_by_hour
        trade_duration = purchase.analyze_trade_duration

        render_success({
          bot_purchase_id: purchase.id,
          bot_name: purchase.trading_bot.name,
          period: period,
          total_profit: trades_array.sum(&:profit).round(2),
          total_trades: trades_array.count,
          daily_profits: daily_profits,
          performance_by_day_of_week: by_day_of_week,
          performance_by_hour: by_hour,
          trade_duration_stats: trade_duration,
          best_performing_day: purchase.get_best_performing_day,
          most_active_day: purchase.get_most_active_day,
          best_performing_hour: purchase.get_best_performing_hour
        })
      end

      def portfolio_overview
        accounts = current_user.mt5_accounts
        period = params[:period] || '30_days'
        date_range = get_date_range(period)

        total_balance = accounts.sum(:balance)
        total_profit = current_user.trades.where(close_time: date_range).sum(:profit)

        account_performances = accounts.map do |account|
          account_trades = account.trades.where(close_time: date_range).closed
          {
            account_id: account.id,
            account_name: account.account_name,
            balance: account.balance,
            profit: account_trades.sum(&:profit).round(2),
            trades_count: account_trades.count
          }
        end

        bot_performances = current_user.bot_purchases.active.map do |purchase|
          bot_trades = purchase.associated_trades.where(close_time: date_range).closed
          {
            bot_purchase_id: purchase.id,
            bot_name: purchase.trading_bot.name,
            profit: bot_trades.sum(&:profit).round(2),
            trades_count: bot_trades.count,
            is_running: purchase.is_running
          }
        end

        render_success({
          period: period,
          total_balance: total_balance.round(2),
          total_profit: total_profit.round(2),
          accounts_count: accounts.count,
          active_bots_count: current_user.bot_purchases.where(status: 'active', is_running: true).count,
          account_performances: account_performances,
          bot_performances: bot_performances
        })
      end

      private

      def get_date_range(period)
        case period
        when "7_days" then 7.days.ago..Time.current
        when "30_days" then 30.days.ago..Time.current
        when "3_months" then 3.months.ago..Time.current
        when "6_months" then 6.months.ago..Time.current
        when "1_year" then 1.year.ago..Time.current
        when "all" then Time.at(0)..Time.current
        else 30.days.ago..Time.current
        end
      end
    end
  end
end

