module Admin
  class CreditsController < BaseController
    def index
      @credits = Credit.includes(:user).order(created_at: :desc)
    end

    def create
      @credit = Credit.new(credit_params)
      if @credit.save
        redirect_to admin_client_path(@credit.user), notice: "Credit created successfully"
      else
        @client = @credit.user
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        @payments = @client.payments.recent
        @credits = @client.credits.recent
        render "admin/clients/show", status: :unprocessable_entity
      end
    end

    def destroy
      @credit = Credit.find(params[:id])
      user = @credit.user
      @credit.destroy
      redirect_to admin_client_path(user), notice: "Credit deleted successfully"
    end

    private

    def credit_params
      params.require(:credit).permit(:user_id, :amount, :reason)
    end
  end
end

