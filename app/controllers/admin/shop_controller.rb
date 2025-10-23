module Admin
  class ShopController < BaseController
    def index
      if current_user.is_admin?
        @trading_bots = TradingBot.all.order(:name)
      else
        @trading_bots = TradingBot.active.order(:name)
        @my_bots = current_user.bot_purchases.includes(:trading_bot).active
      end
    end

    def purchase
      @bot = TradingBot.find(params[:id])
      
      if current_user.bot_purchases.exists?(trading_bot_id: @bot.id, status: "active")
        redirect_to admin_shop_index_path, alert: "You already own this bot"
        return
      end

      if current_user.total_credits >= @bot.price
        ActiveRecord::Base.transaction do
          current_user.bot_purchases.create!(
            trading_bot: @bot,
            price_paid: @bot.price,
            status: "active"
          )
          
          current_user.credits.create!(
            amount: -@bot.price,
            reason: "Purchase: #{@bot.name}"
          )
        end
        
        redirect_to admin_shop_index_path, notice: "Bot purchased successfully!"
      else
        redirect_to admin_shop_index_path, alert: "Insufficient credits. You need #{number_to_currency(@bot.price - current_user.total_credits, unit: '$')} more."
      end
    end

    private

    def number_to_currency(value, options = {})
      ActionController::Base.helpers.number_to_currency(value, options)
    end
  end
end

