module Admin
  class ClientsController < BaseController
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

    def update
      @client = User.find(params[:id])
      if @client.update(client_params)
        redirect_to admin_client_path(@client), notice: "Client updated successfully"
      else
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        @payments = @client.payments.recent
        @credits = @client.credits.recent
        render :show, status: :unprocessable_entity
      end
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
  end
end

