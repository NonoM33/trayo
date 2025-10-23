module Admin
  class SessionsController < ApplicationController
    def new
    end

    def create
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password]) && user.is_admin?
        session[:user_id] = user.id
        redirect_to admin_clients_path, notice: "Logged in successfully"
      else
        flash.now[:alert] = "Invalid credentials or not an admin"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session[:user_id] = nil
      redirect_to admin_login_path, notice: "Logged out successfully"
    end
  end
end

