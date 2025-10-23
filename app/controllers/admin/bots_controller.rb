module Admin
  class BotsController < BaseController
    before_action :require_admin
    before_action :set_bot, only: [:show, :edit, :update, :destroy, :remove_from_user]

    def index
      @bots = TradingBot.order(created_at: :desc)
    end

    def show
      @purchases = @bot.bot_purchases.includes(:user).order(created_at: :desc)
    end

    def new
      @bot = TradingBot.new
    end

    def create
      @bot = TradingBot.new(bot_params)
      
      if @bot.save
        redirect_to admin_bots_path, notice: "Bot créé avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @bot.update(bot_params)
        redirect_to admin_bot_path(@bot), notice: "Bot mis à jour avec succès"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @bot.destroy
      redirect_to admin_bots_path, notice: "Bot supprimé avec succès"
    end

    def assign_to_user
      user = User.find(params[:user_id])
      bot = TradingBot.find(params[:bot_id])
      
      purchase = BotPurchase.create(
        user: user,
        trading_bot: bot,
        price_paid: params[:price_paid].present? ? params[:price_paid] : bot.price,
        status: 'active'
      )
      
      if purchase.persisted?
        redirect_to admin_client_path(user), notice: "Bot assigné au client avec succès"
      else
        redirect_to admin_client_path(user), alert: "Erreur lors de l'assignation du bot"
      end
    end

    def remove_from_user
      purchase = BotPurchase.find(params[:purchase_id])
      purchase.destroy
      redirect_to admin_client_path(purchase.user), notice: "Bot retiré du client"
    end

    private

    def set_bot
      @bot = TradingBot.find(params[:id])
    end

    def bot_params
      params.require(:trading_bot).permit(
        :name, :description, :price, :status, :image_url,
        :projection_monthly_min, :projection_monthly_max, :projection_yearly,
        :win_rate, :max_drawdown_limit, :strategy_description,
        :risk_level, :is_active, features: []
      )
    end
  end
end

