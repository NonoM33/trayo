module Admin
  class WithdrawalsController < BaseController
    before_action :require_admin
    before_action :set_withdrawal, only: [:show, :edit, :update, :destroy]

    def index
      @withdrawals = Withdrawal.joins(mt5_account: :user)
                              .includes(:mt5_account, mt5_account: :user)
                              .order(withdrawal_date: :desc)
                              .page(params[:page]).per(50)
    end

    def show
    end

    def new
      @withdrawal = Withdrawal.new
      @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
    end

    def create
      @withdrawal = Withdrawal.new(withdrawal_params)
      
      if @withdrawal.save
        redirect_to admin_client_path(@withdrawal.mt5_account.user), 
                    notice: 'Retrait créé avec succès.'
      else
        @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
    end

    def update
      if @withdrawal.update(withdrawal_params)
        redirect_to admin_client_path(@withdrawal.mt5_account.user), 
                    notice: 'Retrait mis à jour avec succès.'
      else
        @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      user = @withdrawal.mt5_account.user
      @withdrawal.destroy
      redirect_to admin_client_path(user), 
                  notice: 'Retrait supprimé avec succès.'
    end

    private

    def set_withdrawal
      @withdrawal = Withdrawal.find(params[:id])
    end

    def withdrawal_params
      params.require(:withdrawal).permit(:mt5_account_id, :amount, :withdrawal_date, :notes)
    end
  end
end