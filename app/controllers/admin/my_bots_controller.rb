module Admin
  class MyBotsController < BaseController
    before_action :set_purchase, only: [:show, :toggle_status]

    def index
      if current_user.is_admin?
        redirect_to admin_bots_path
      else
        @purchases = current_user.bot_purchases.includes(:trading_bot).order(created_at: :desc)
      end
    end

    def show
      unless current_user.is_admin? || @purchase.user_id == current_user.id
        redirect_to admin_my_bots_path, alert: "Accès refusé"
      end
    end

    def toggle_status
      if current_user.is_admin? || @purchase.user_id == current_user.id
        @purchase.toggle_status!
        message = @purchase.is_running? ? "Bot activé avec succès" : "Bot arrêté avec succès"
        
        if request.referer&.include?('clients')
          redirect_to admin_client_path(@purchase.user), notice: message
        else
          redirect_to admin_my_bots_path, notice: message
        end
      else
        redirect_to admin_my_bots_path, alert: "Accès refusé"
      end
    end

    private

    def set_purchase
      @purchase = BotPurchase.find(params[:id])
    end
  end
end

