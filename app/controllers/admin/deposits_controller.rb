module Admin
  class DepositsController < BaseController
    before_action :require_admin
    before_action :set_deposit, only: [:show, :edit, :update, :destroy]

    def index
      @deposits = Deposit.joins(mt5_account: :user)
                        .includes(:mt5_account, mt5_account: :user)
                        .order(deposit_date: :desc)
                        .page(params[:page]).per(50)
    end

    def show
    end

    def new
      @deposit = Deposit.new
      @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
    end

    def create
      @deposit = Deposit.new(deposit_params)
      
      if @deposit.save
        redirect_to admin_client_path(@deposit.mt5_account.user), 
                    notice: 'Dépôt créé avec succès.'
      else
        @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
    end

    def update
      if @deposit.update(deposit_params)
        redirect_to admin_client_path(@deposit.mt5_account.user), 
                    notice: 'Dépôt mis à jour avec succès.'
      else
        @mt5_accounts = Mt5Account.joins(:user).order('users.first_name, users.last_name')
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      user = @deposit.mt5_account.user
      @deposit.destroy
      redirect_to admin_client_path(user), 
                  notice: 'Dépôt supprimé avec succès.'
    end

    private

    def set_deposit
      @deposit = Deposit.find(params[:id])
    end

    def deposit_params
      params.require(:deposit).permit(:mt5_account_id, :amount, :deposit_date, :notes)
    end
  end
end
