module Admin
  class Mt5AccountsController < BaseController
    def update
      @mt5_account = Mt5Account.find(params[:id])
      @client = @mt5_account.user
      
      # Gérer la mise à jour du mot de passe broker
      if params[:new_password].present?
        @mt5_account.update(broker_password: params[:new_password])
        redirect_to admin_client_path(@client), notice: "Mot de passe broker mis à jour avec succès !"
        return
      end
      
      # Gérer la mise à jour du nom du broker
      if params[:broker_name].present?
        @mt5_account.update(broker_name: params[:broker_name])
        redirect_to admin_client_path(@client), notice: "Nom du broker mis à jour avec succès !"
        return
      end
      
      # Gérer la mise à jour du serveur broker
      if params[:broker_server].present?
        @mt5_account.update(broker_server: params[:broker_server])
        redirect_to admin_client_path(@client), notice: "Serveur broker mis à jour avec succès !"
        return
      end
      
      # Gérer le recalcul de la balance initiale
      if params[:action] == 'recalculate_initial_balance'
        @mt5_account.force_recalculate_initial_balance!
        redirect_to admin_client_path(@client), notice: "Balance initiale recalculée avec succès !"
        return
      end
      
      # Gérer les retraits si des données sont fournies
      if params[:withdrawal_amount].present? && params[:withdrawal_amount].to_f > 0
        withdrawal_amount = params[:withdrawal_amount].to_f
        withdrawal_date = params[:withdrawal_date].present? ? Date.parse(params[:withdrawal_date]) : Date.current
        
        # Créer un nouveau retrait
        withdrawal = @mt5_account.withdrawals.build(
          amount: withdrawal_amount,
          withdrawal_date: withdrawal_date
        )
        
        if withdrawal.save
          # Mettre à jour le total des retraits
          @mt5_account.update(total_withdrawals: @mt5_account.withdrawals.sum(:amount))
        else
          flash.now[:alert] = "Erreur lors de l'enregistrement du retrait: #{withdrawal.errors.full_messages.join(', ')}"
          @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
          @payments = @client.payments.recent
          @credits = @client.credits.recent
          render "admin/clients/show", status: :unprocessable_entity
          return
        end
      end
      
      if @mt5_account.update(mt5_account_params)
        @client.reload
        @mt5_account.reload
        redirect_to admin_client_path(@client), notice: "Account parameters updated successfully"
      else
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        @payments = @client.payments.recent
        @credits = @client.credits.recent
        flash.now[:alert] = "Error updating account: #{@mt5_account.errors.full_messages.join(', ')}"
        render "admin/clients/show", status: :unprocessable_entity
      end
    end

    private

    def mt5_account_params
      params.require(:mt5_account).permit(:account_name, :mt5_id, :high_watermark, :initial_balance, :total_withdrawals, :is_admin_account, :broker_name, :broker_server, :broker_password)
    end
  end
end

