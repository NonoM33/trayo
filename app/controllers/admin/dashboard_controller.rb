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
      trades = current_user.trades.where('close_time >= ?', 12.months.ago)
                          .group_by { |t| t.close_time.beginning_of_month }
      
      (0..11).map do |i|
        month = i.months.ago.beginning_of_month
        {
          month: month.strftime('%b %Y'),
          profit: trades[month]&.sum(&:profit) || 0
        }
      end.reverse
    end

    def calculate_projection
      return [] if current_user.trades.empty?
      
      last_6_months_avg = current_user.trades
                                      .where('close_time >= ?', 6.months.ago)
                                      .average(:profit)
                                      .to_f
      
      current_balance = current_user.mt5_accounts.sum(:balance)
      
      (0..5).map do |i|
        month = i.months.from_now.beginning_of_month
        projected_balance = current_balance + (last_6_months_avg * i * 30)
        {
          month: month.strftime('%b %Y'),
          balance: projected_balance
        }
      end
    end
  end
end

