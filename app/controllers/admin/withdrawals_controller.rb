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

    def bulk_destroy
      Rails.logger.info "=== BULK DESTROY WITHDRAWALS ==="
      Rails.logger.info "Params: #{params.inspect}"
      Rails.logger.info "Withdrawal IDs: #{params[:withdrawal_ids].inspect}"
      Rails.logger.info "User ID: #{params[:user_id].inspect}"
      
      withdrawal_ids = params[:withdrawal_ids] || []
      user_id = params[:user_id]
      
      if withdrawal_ids.empty?
        Rails.logger.warn "Aucun retrait sélectionné"
        redirect_to admin_client_path(user_id), alert: 'Aucun retrait sélectionné.'
        return
      end

      withdrawals = Withdrawal.where(id: withdrawal_ids).includes(:mt5_account)
      Rails.logger.info "Withdrawals trouvés: #{withdrawals.count}"
      
      user = withdrawals.first&.mt5_account&.user if withdrawals.any?
      
      mt5_accounts_to_update = withdrawals.map(&:mt5_account).uniq
      
      count = withdrawals.count
      withdrawals.destroy_all
      
      mt5_accounts_to_update.each do |account|
        account.update(total_withdrawals: account.withdrawals.sum(:amount) || 0)
      end
      
      Rails.logger.info "=== FIN BULK DESTROY ==="
      redirect_to admin_client_path(user || user_id), 
                  notice: "#{count} retrait(s) supprimé(s) avec succès."
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