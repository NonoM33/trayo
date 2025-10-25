module Admin
  class ClientsController < BaseController
    before_action :require_admin, except: [:show]
    before_action :ensure_own_profile_or_admin, only: [:show]
    
    def index
      @clients = User.clients.order(:email)
      @admins = User.admins.order(:email)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_create_params)
      if @user.save
        redirect_to admin_clients_path, notice: "User created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @client = User.find(params[:id])
      @client.reload
      @mt5_accounts = @client.mt5_accounts.reload.includes(:trades, :withdrawals)
      @payments = @client.payments.recent
      @credits = @client.credits.recent
    end

    def edit
      @client = User.find(params[:id])
    end

    def update
      @client = User.find(params[:id])
      if @client.update(user_update_params)
        redirect_to admin_client_path(@client), notice: "User updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reset_password
      @client = User.find(params[:id])
      new_password = params[:new_password].presence || SecureRandom.alphanumeric(12)
      
      if @client.update(password: new_password, password_confirmation: new_password)
        if params[:send_email]
          flash[:notice] = "Password reset successfully. Email sent to #{@client.email} with new password: #{new_password}"
        else
          flash[:notice] = "Password reset successfully. New password: #{new_password}"
        end
      else
        flash[:alert] = "Failed to reset password"
      end
      
      redirect_to edit_admin_client_path(@client)
    end

    def regenerate_token
      @client = User.find(params[:id])
      @client.update(mt5_api_token: SecureRandom.hex(32))
      redirect_to edit_admin_client_path(@client), notice: "API token regenerated successfully"
    end

    def trades
      @client = User.find(params[:id])
      
      # Récupérer tous les trades de tous les comptes MT5 du client
      @trades = Trade.joins(:mt5_account)
                    .where(mt5_accounts: { user_id: @client.id })
                    .includes(:mt5_account)
                    .order(close_time: :desc)
      
      # Filtres
      if params[:symbol].present?
        @trades = @trades.where(symbol: params[:symbol])
      end
      
      if params[:magic_number].present?
        @trades = @trades.where(magic_number: params[:magic_number])
      end
      
      if params[:date_from].present?
        @trades = @trades.where('close_time >= ?', Date.parse(params[:date_from]).beginning_of_day)
      end
      
      if params[:date_to].present?
        @trades = @trades.where('close_time <= ?', Date.parse(params[:date_to]).end_of_day)
      end
      
      # Tri
      case params[:sort]
      when 'symbol'
        @trades = @trades.order(:symbol, close_time: :desc)
      when 'profit'
        @trades = @trades.order(:profit)
      when 'magic_number'
        @trades = @trades.order(:magic_number, close_time: :desc)
      when 'close_time'
        @trades = @trades.order(close_time: :desc)
      else
        @trades = @trades.order(close_time: :desc)
      end
      
      # Pagination
      @trades = @trades.page(params[:page]).per(50)
      
      # Statistiques
      @total_trades = @trades.total_count
      @total_profit = @trades.sum(:profit)
      @winning_trades = @trades.where('profit > 0').count
      @losing_trades = @trades.where('profit < 0').count
      @win_rate = @total_trades > 0 ? (@winning_trades.to_f / @total_trades * 100).round(2) : 0
      
      # Options pour les filtres
      @symbols = Trade.joins(:mt5_account)
                     .where(mt5_accounts: { user_id: @client.id })
                     .distinct.pluck(:symbol).compact.sort
      
      @magic_numbers = Trade.joins(:mt5_account)
                           .where(mt5_accounts: { user_id: @client.id })
                           .distinct.pluck(:magic_number).compact.sort
    end

    def destroy
      @user = User.find(params[:id])
      if @user.id == current_user.id
        redirect_to admin_clients_path, alert: "You cannot delete yourself"
        return
      end
      
      @user.destroy
      redirect_to admin_clients_path, notice: "User deleted successfully"
    end

    private

    def client_params
      params.require(:user).permit(:commission_rate)
    end

    def user_create_params
      params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :commission_rate, :is_admin)
    end

    def user_update_params
      params.require(:user).permit(:email, :first_name, :last_name, :phone, :commission_rate, :is_admin)
    end

    def ensure_own_profile_or_admin
      @client = User.find(params[:id])
      unless current_user.is_admin? || current_user.id == @client.id
        redirect_to admin_client_path(current_user), alert: "You can only view your own profile"
      end
    end
  end
end

