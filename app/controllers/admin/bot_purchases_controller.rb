module Admin
  class BotPurchasesController < BaseController
    before_action :set_bot_purchase

    def update
      if @bot_purchase.update(bot_purchase_params)
        respond_to do |format|
          format.turbo_stream { render_turbo_update("Bot mis à jour", :success) }
          format.html { redirect_back fallback_location: admin_client_path(@bot_purchase.user), notice: "Bot mis à jour" }
        end
      else
        respond_to do |format|
          format.turbo_stream { render_turbo_update("Erreur: #{@bot_purchase.errors.full_messages.join(', ')}", :error) }
          format.html { redirect_back fallback_location: admin_client_path(@bot_purchase.user), alert: "Erreur: #{@bot_purchase.errors.full_messages.join(', ')}" }
        end
      end
    end

    def toggle_running
      if @bot_purchase.is_running?
        @bot_purchase.stop!
      else
        @bot_purchase.start!
      end
      
      message = "Bot #{@bot_purchase.is_running? ? 'démarré' : 'arrêté'}"
      respond_to do |format|
        format.turbo_stream { render_turbo_update(message, :success) }
        format.html { redirect_back fallback_location: admin_client_path(@bot_purchase.user), notice: message }
      end
    end

    private

    def set_bot_purchase
      @bot_purchase = BotPurchase.find(params[:id])
    end

    def bot_purchase_params
      params.require(:bot_purchase).permit(:status, :is_running)
    end

    def render_turbo_update(message, type)
      render turbo_stream: [
        turbo_stream.replace("bot_purchase_#{@bot_purchase.id}", partial: "admin/clients/bot_purchase_card", locals: { bot: @bot_purchase }),
        turbo_stream.replace("flash_messages", partial: "shared/flash_toast", locals: { message: message, type: type })
      ]
    end
  end
end
