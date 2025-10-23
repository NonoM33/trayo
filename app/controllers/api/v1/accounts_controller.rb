module Api
  module V1
    class AccountsController < ApplicationController
      include Authenticable
      skip_before_action :verify_authenticity_token

      def balance
        mt5_accounts = current_user.mt5_accounts
        
        render json: {
          accounts: mt5_accounts.map do |account|
            {
              id: account.id,
              mt5_id: account.mt5_id,
              account_name: account.account_name,
              balance: account.balance,
              last_sync_at: account.last_sync_at
            }
          end,
          total_balance: mt5_accounts.sum(:balance)
        }, status: :ok
      end

      def recent_trades
        mt5_accounts = current_user.mt5_accounts.includes(:trades)
        
        all_trades = Trade.where(mt5_account_id: mt5_accounts.pluck(:id))
                          .order(close_time: :desc)
                          .limit(20)
        
        render json: {
          trades: all_trades.map do |trade|
            {
              id: trade.id,
              trade_id: trade.trade_id,
              account_name: trade.mt5_account.account_name,
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
              status: trade.status
            }
          end
        }, status: :ok
      end

      def projection
        mt5_accounts = current_user.mt5_accounts
        days = params[:days]&.to_i || 30
        
        projections = mt5_accounts.map do |account|
          projection_data = account.calculate_projection(days)
          {
            account_id: account.id,
            mt5_id: account.mt5_id,
            account_name: account.account_name,
            current_balance: account.balance,
            **projection_data
          }
        end

        total_current = mt5_accounts.sum(:balance)
        total_projected = projections.sum { |p| p[:projected_balance] }

        render json: {
          projections: projections,
          summary: {
            total_current_balance: total_current,
            total_projected_balance: total_projected.round(2),
            projected_difference: (total_projected - total_current).round(2),
            projection_days: days
          }
        }, status: :ok
      end
    end
  end
end

