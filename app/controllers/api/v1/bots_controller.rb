module Api
  module V1
    class BotsController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_api_user

      def status
        bot_purchase = current_api_user.bot_purchases.find_by(id: params[:purchase_id])
        
        if bot_purchase
          render json: {
            success: true,
            bot_name: bot_purchase.trading_bot.name,
            is_running: bot_purchase.is_running,
            max_drawdown_limit: bot_purchase.trading_bot.max_drawdown_limit,
            current_drawdown: bot_purchase.current_drawdown,
            total_profit: bot_purchase.total_profit,
            trades_count: bot_purchase.trades_count,
            message: bot_purchase.is_running ? "Bot active - trading autorisé" : "Bot en pause - ne pas trader"
          }
        else
          render json: {
            success: false,
            is_running: false,
            message: "Bot non trouvé ou non assigné"
          }, status: :not_found
        end
      end

      def update_performance
        bot_purchase = current_api_user.bot_purchases.find_by(id: params[:purchase_id])
        
        if bot_purchase
          bot_purchase.update_performance(
            params[:profit].to_f,
            params[:drawdown].to_f
          )
          
          render json: {
            success: true,
            message: "Performance mise à jour",
            is_running: bot_purchase.is_running,
            within_drawdown_limit: bot_purchase.within_drawdown_limit?
          }
        else
          render json: {
            success: false,
            message: "Bot non trouvé"
          }, status: :not_found
        end
      end

      def list
        purchases = current_api_user.bot_purchases.includes(:trading_bot).where(status: 'active')
        
        render json: {
          success: true,
          bots: purchases.map do |purchase|
            {
              purchase_id: purchase.id,
              bot_id: purchase.trading_bot.id,
              bot_name: purchase.trading_bot.name,
              is_running: purchase.is_running,
              max_drawdown_limit: purchase.trading_bot.max_drawdown_limit,
              current_drawdown: purchase.current_drawdown,
              total_profit: purchase.total_profit
            }
          end
        }
      end

      private

      def authenticate_api_user
        token = request.headers['Authorization']&.split(' ')&.last || params[:api_token]
        @current_api_user = User.find_by(mt5_api_token: token)
        
        unless @current_api_user
          render json: { error: 'Invalid API token' }, status: :unauthorized
        end
      end

      def current_api_user
        @current_api_user
      end
    end
  end
end

