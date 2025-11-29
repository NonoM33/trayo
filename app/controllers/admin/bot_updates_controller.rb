module Admin
  class BotUpdatesController < BaseController
    before_action :require_admin, except: [:index, :show, :purchase, :purchase_pass]
    before_action :set_bot
    before_action :set_update, only: [:show, :edit, :update, :destroy, :notify_users, :purchase]

    def index
      @updates = @bot.bot_updates.recent
      @users_needing_update = @bot.users_needing_update
      @update_revenue = @bot.update_revenue
    end

    def show
      @purchased_users = @update.users
      @pending_users = @bot.bot_purchases
                           .where("version_purchased < ?", @update.version)
                           .includes(:user)
                           .map(&:user)
    end

    def new
      current = @bot.current_version || "1.0.0"
      parts = current.split('.').map(&:to_i)
      suggested_version = "#{parts[0]}.#{parts[1]}.#{parts[2] + 1}"
      
      @update = @bot.bot_updates.build(version: suggested_version)
    end

    def create
      @update = @bot.bot_updates.build(update_params)
      
      if @update.save
        redirect_to admin_bot_bot_updates_path(@bot), notice: "Mise à jour v#{@update.version} créée avec succès!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @update.update(update_params)
        redirect_to admin_bot_bot_updates_path(@bot), notice: "Mise à jour modifiée"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @update.destroy
      redirect_to admin_bot_bot_updates_path(@bot), notice: "Mise à jour supprimée"
    end

    def notify_users
      users_to_notify = @bot.users_needing_update
      
      redirect_to admin_bot_bot_updates_path(@bot), notice: "#{users_to_notify.count} utilisateurs notifiés"
    end

    def purchase
      bot_purchase = current_user.bot_purchases.find_by(trading_bot: @bot)
      
      unless bot_purchase
        render json: { error: "Vous devez d'abord acheter ce bot" }, status: :unprocessable_entity
        return
      end

      if @update.already_upgraded?(current_user)
        render json: { error: "Vous avez déjà cette mise à jour" }, status: :unprocessable_entity
        return
      end

      price = @update.price_for_user(current_user)
      
      if price.zero?
        @update.upgrade_user!(current_user)
        render json: { success: true, free: true, bot_name: @bot.name, version: @update.version }
        return
      end

      unless Stripe.api_key.present?
        render json: { error: "Configuration Stripe manquante. Contactez l'administrateur." }, status: :unprocessable_entity
        return
      end

      payment_intent = Stripe::PaymentIntent.create(
        amount: (price * 100).to_i,
        currency: 'eur',
        metadata: {
          user_id: current_user.id,
          bot_purchase_id: bot_purchase.id,
          bot_update_id: @update.id,
          type: 'bot_update_single'
        }
      )

      BotUpdatePurchase.create!(
        user: current_user,
        bot_purchase: bot_purchase,
        bot_update: @update,
        purchase_type: 'single',
        price_paid: price,
        status: 'pending',
        stripe_payment_intent_id: payment_intent.id
      )

      render json: { 
        clientSecret: payment_intent.client_secret,
        amount: price,
        bot_name: @bot.name,
        version: @update.version
      }
    rescue Stripe::StripeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Bot update purchase error: #{e.message}"
      render json: { error: "Erreur lors du paiement. Veuillez réessayer." }, status: :unprocessable_entity
    end

    def purchase_pass
      bot_purchase = current_user.bot_purchases.find_by(trading_bot: @bot)
      
      unless bot_purchase
        render json: { error: "Vous devez d'abord acheter ce bot" }, status: :unprocessable_entity
        return
      end

      if bot_purchase.update_pass_active?
        render json: { error: "Vous avez déjà un pass annuel actif" }, status: :unprocessable_entity
        return
      end

      unless Stripe.api_key.present?
        render json: { error: "Configuration Stripe manquante. Contactez l'administrateur." }, status: :unprocessable_entity
        return
      end

      latest_update = @bot.latest_update || @bot.bot_updates.create!(
        version: @bot.current_version,
        title: "Version actuelle",
        is_free: true
      )

      price = @bot.update_pass_yearly_price

      payment_intent = Stripe::PaymentIntent.create(
        amount: (price * 100).to_i,
        currency: 'eur',
        metadata: {
          user_id: current_user.id,
          bot_purchase_id: bot_purchase.id,
          bot_update_id: latest_update.id,
          type: 'bot_update_yearly_pass'
        }
      )

      BotUpdatePurchase.create!(
        user: current_user,
        bot_purchase: bot_purchase,
        bot_update: latest_update,
        purchase_type: 'yearly_pass',
        price_paid: price,
        status: 'pending',
        stripe_payment_intent_id: payment_intent.id
      )

      render json: { 
        clientSecret: payment_intent.client_secret,
        amount: price,
        bot_name: @bot.name,
        yearly: true
      }
    rescue Stripe::StripeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Bot update pass purchase error: #{e.message}"
      render json: { error: "Erreur lors du paiement. Veuillez réessayer." }, status: :unprocessable_entity
    end

    private

    def set_bot
      @bot = TradingBot.find(params[:bot_id])
    end

    def set_update
      @update = @bot.bot_updates.find(params[:id])
    end

    def update_params
      params.require(:bot_update).permit(
        :version, :title, :description, :changelog, :highlights,
        :is_major, :is_free, :released_at, :notify_users
      )
    end

    def require_admin
      redirect_to admin_dashboard_path, alert: "Accès non autorisé" unless current_user.is_admin?
    end
  end
end

