module Admin
  class Mt5AccountsController < BaseController
    def update
      @mt5_account = Mt5Account.find(params[:id])
      @client = @mt5_account.user
      
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
      params.require(:mt5_account).permit(:high_watermark, :initial_balance)
    end
  end
end

