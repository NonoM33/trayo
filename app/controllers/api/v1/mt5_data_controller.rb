module Api
  module V1
    class Mt5DataController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :verify_api_key

      def sync
        mt5_account = Mt5Account.find_or_initialize_by(mt5_id: sync_params[:mt5_id])
        
        if mt5_account.new_record?
          user = User.find_by(mt5_api_token: sync_params[:mt5_api_token])
          unless user
            render json: { error: "Invalid MT5 API token" }, status: :not_found
            return
          end
          mt5_account.user = user
        end

        old_balance = mt5_account.balance
        new_balance = sync_params[:balance].to_f

        detect_withdrawal(mt5_account, old_balance, new_balance)

        mt5_account.update_from_mt5_data(
          account_name: sync_params[:account_name],
          balance: new_balance
        )

        sync_trades(mt5_account, sync_params[:trades]) if sync_params[:trades].present?
        
        sync_bot_performances(mt5_account.user)

        render json: {
          message: "Data synchronized successfully",
          mt5_account: {
            id: mt5_account.id,
            mt5_id: mt5_account.mt5_id,
            account_name: mt5_account.account_name,
            balance: mt5_account.balance,
            last_sync_at: mt5_account.last_sync_at,
            high_watermark: mt5_account.high_watermark,
            total_withdrawals: mt5_account.total_withdrawals
          },
          trades_synced: sync_params[:trades]&.count || 0
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def verify_api_key
        api_key = request.headers["X-API-Key"]
        expected_key = ENV["MT5_API_KEY"] || "mt5_secret_key_change_in_production"
        
        unless api_key == expected_key
          render json: { error: "Invalid API key" }, status: :unauthorized
        end
      end

      def sync_params
        params.require(:mt5_data).permit(
          :mt5_id,
          :mt5_api_token,
          :account_name,
          :balance,
          trades: [
            :trade_id,
            :symbol,
            :trade_type,
            :volume,
            :open_price,
            :close_price,
            :profit,
            :commission,
            :swap,
            :open_time,
            :close_time,
            :status,
            :magic_number,
            :comment
          ]
        )
      end

      def sync_trades(mt5_account, trades_data)
        trades_data.each do |trade_data|
          Trade.create_or_update_from_mt5(mt5_account, trade_data.to_h.symbolize_keys)
        end
      end

      def detect_withdrawal(mt5_account, old_balance, new_balance)
        return if mt5_account.new_record?
        return if old_balance >= new_balance

        balance_decrease = old_balance - new_balance
        return if balance_decrease <= 0

        recent_losses = mt5_account.trades
          .where("close_time >= ?", 1.hour.ago)
          .where("profit < ?", 0)
          .sum(:profit)
          .abs

        if balance_decrease > (recent_losses + 10)
          Withdrawal.create!(
            mt5_account: mt5_account,
            amount: balance_decrease,
            withdrawal_date: Time.current
          )
        end
      end
      
      def sync_bot_performances(user)
        user.bot_purchases.each do |purchase|
          purchase.sync_performance_from_trades
        end
      end
    end
  end
end

