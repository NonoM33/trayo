module Admin
  class ShopController < BaseController
    def index
      @bots = TradingBot.available.where(status: 'active').order(:name)
      @my_bot_ids = current_user.bot_purchases.where(status: 'active').pluck(:trading_bot_id)
    end

    def show
      @bot = TradingBot.find(params[:id])
      @already_owned = current_user.bot_purchases.exists?(trading_bot_id: @bot.id, status: 'active')
    end

    def purchase
      @bot = TradingBot.find(params[:id])
      
      if current_user.bot_purchases.exists?(trading_bot_id: @bot.id, status: "active")
        redirect_to admin_shop_index_path, alert: "Vous possédez déjà ce bot"
        return
      end

      purchase = nil
      ActiveRecord::Base.transaction do
        purchase = current_user.bot_purchases.create!(
          trading_bot: @bot,
          price_paid: @bot.price,
          status: "active",
          is_running: false
        )

        Invoices::Builder.new(
          user: current_user,
          source: "shop",
          metadata: { bot_id: @bot.id },
          deactivate_bots: true
        ).build_from_selection(
          bot_purchases: [purchase],
          vps_list: []
        )
      end
      
      redirect_to admin_my_bots_path, notice: "🎉 Bot réservé ! Facture créée, statut en attente de règlement."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_shop_path(@bot), alert: "Erreur lors de l'achat: #{e.message}"
    end
  end
end

