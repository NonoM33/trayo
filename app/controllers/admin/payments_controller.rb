module Admin
  class PaymentsController < BaseController
    before_action :require_admin
    
    def index
      @payments = Payment.includes(:user).order(payment_date: :desc)
    end
    
    def show
      @payment = Payment.find(params[:id])
      prepare_capital_evolution_data
      @user_bots = @payment.user.bot_purchases.includes(:trading_bot).order(created_at: :desc)
    end
    
    def prepare_capital_evolution_data
      user = @payment.user
      
      @capital_evolution = []
      all_trades = []
      
      user.mt5_accounts.each do |account|
        trades = account.trades.closed.where.not(close_time: nil).order(close_time: :asc)
        
        trades.each do |trade|
          all_trades << {
            date: trade.close_time,
            profit: trade.profit,
            account_name: account.account_name,
            account_mt5_id: account.mt5_id
          }
        end
      end
      
      all_trades.sort_by! { |t| t[:date] }
      
      if all_trades.any?
        total_initial_balance = user.mt5_accounts.sum do |account|
          account.auto_calculated_initial_balance && account.calculated_initial_balance.present? ? 
            account.calculated_initial_balance : account.initial_balance
        end
        
        running_balance = total_initial_balance
        
        all_trades.each do |trade|
          running_balance += trade[:profit]
          
          @capital_evolution << {
            date: trade[:date],
            balance: running_balance,
            account_name: trade[:account_name],
            account_mt5_id: trade[:account_mt5_id]
          }
        end
      else
        total_initial_balance = user.mt5_accounts.sum do |account|
          account.auto_calculated_initial_balance && account.calculated_initial_balance.present? ? 
            account.calculated_initial_balance : account.initial_balance
        end
        
        @capital_evolution = [{
          date: @payment.payment_date,
          balance: total_initial_balance,
          account_name: "Aucune donnée",
          account_mt5_id: "N/A"
        }]
      end
    end
    
    def download_pdf
      @payment = Payment.find(params[:id])
      
      render :show, layout: false
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
      params.require(:payment).permit(:user_id, :amount, :payment_date, :reference, :notes, :payment_method, :manual_watermark)
    end
  end
end

