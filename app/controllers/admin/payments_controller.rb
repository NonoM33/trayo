module Admin
  class PaymentsController < BaseController
    def index
      @payments = Payment.includes(:user).order(payment_date: :desc)
    end

    def create
      @payment = Payment.new(payment_params)
      if @payment.save
        redirect_to admin_client_path(@payment.user), notice: "Payment created successfully"
      else
        @client = @payment.user
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        @payments = @client.payments.recent
        @credits = @client.credits.recent
        render "admin/clients/show", status: :unprocessable_entity
      end
    end

    def update
      @payment = Payment.find(params[:id])
      if params[:action_type] == "validate"
        @payment.validate!
        redirect_to admin_client_path(@payment.user), notice: "Payment validated"
      elsif params[:action_type] == "reject"
        @payment.reject!
        redirect_to admin_client_path(@payment.user), notice: "Payment rejected"
      else
        redirect_to admin_client_path(@payment.user), alert: "Invalid action"
      end
    end

    def destroy
      @payment = Payment.find(params[:id])
      user = @payment.user
      @payment.destroy
      redirect_to admin_client_path(user), notice: "Payment deleted successfully"
    end

    private

    def payment_params
      params.require(:payment).permit(:user_id, :amount, :payment_date, :reference, :notes, :payment_method)
    end
  end
end

