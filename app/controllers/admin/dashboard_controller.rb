module Admin
  class DashboardController < BaseController
    def index
      if current_user.is_admin?
        redirect_to admin_clients_path
      else
        @client = current_user
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        
        # Statistics for charts
        @monthly_profits = calculate_monthly_profits
        @projection_data = calculate_projection
      end
    end

    private

    def calculate_monthly_profits
      trades_by_month = current_user.trades
                                    .where('close_time >= ?', 12.months.ago)
                                    .group_by { |t| t.close_time.beginning_of_month }
      
      (0..11).map do |i|
        month = i.months.ago.beginning_of_month
        month_profit = trades_by_month[month]&.sum(&:profit) || 0
        {
          month: month.strftime('%b %Y'),
          profit: month_profit.round(2)
        }
      end.reverse
    end

    def calculate_projection
      current_balance = current_user.mt5_accounts.sum(:balance)
      
      recent_trades = current_user.trades.where('close_time >= ?', 6.months.ago)
      
      if recent_trades.empty?
        monthly_avg_profit = 50.0
      else
        total_profit = recent_trades.sum(:profit)
        months_with_trades = recent_trades.group_by { |t| t.close_time.beginning_of_month }.count
        months_with_trades = [months_with_trades, 1].max
        monthly_avg_profit = total_profit / months_with_trades
      end
      
      running_balance = current_balance
      
      (1..6).map do |i|
        month = i.months.from_now.beginning_of_month
        running_balance += monthly_avg_profit
        {
          month: month.strftime('%b %Y'),
          balance: running_balance.round(2)
        }
      end
    end
  end
end

