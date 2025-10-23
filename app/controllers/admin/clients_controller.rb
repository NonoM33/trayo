module Admin
  class ClientsController < BaseController
    before_action :require_admin, except: [:show, :edit, :update]
    before_action :ensure_own_profile_or_admin, only: [:show, :edit, :update]
    
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

