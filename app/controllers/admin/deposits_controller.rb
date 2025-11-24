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

    def bulk_destroy
      Rails.logger.info "=== BULK DESTROY DEPOSITS ==="
      Rails.logger.info "Params: #{params.inspect}"
      Rails.logger.info "Deposit IDs: #{params[:deposit_ids].inspect}"
      Rails.logger.info "User ID: #{params[:user_id].inspect}"
      
      deposit_ids = params[:deposit_ids] || []
      user_id = params[:user_id]
      
      if deposit_ids.empty?
        Rails.logger.warn "Aucun dépôt sélectionné"
        redirect_to admin_client_path(user_id), alert: 'Aucun dépôt sélectionné.'
        return
      end

      deposits = Deposit.where(id: deposit_ids).includes(:mt5_account)
      Rails.logger.info "Deposits trouvés: #{deposits.count}"
      
      user = deposits.first&.mt5_account&.user if deposits.any?
      
      mt5_accounts_to_update = deposits.map(&:mt5_account).uniq
      
      count = deposits.count
      deposits.destroy_all
      
      mt5_accounts_to_update.each do |account|
        account.calculate_initial_balance_from_history
      end
      
      Rails.logger.info "=== FIN BULK DESTROY ==="
      redirect_to admin_client_path(user || user_id), 
                  notice: "#{count} dépôt(s) supprimé(s) avec succès."
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
