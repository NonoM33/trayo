module Admin
  class SessionsController < ApplicationController
    layout false
    
    before_action :redirect_if_authenticated, only: [:new]

    def new
    end

    def create
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        session[:user_id] = user.id
        if user.is_admin?
          redirect_to admin_clients_path, notice: "Welcome back, #{user.first_name || 'Admin'}!"
        else
          redirect_to admin_dashboard_path, notice: "Welcome back, #{user.first_name || user.email}!"
        end
      else
        flash.now[:alert] = "Invalid credentials"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session[:user_id] = nil
      redirect_to admin_login_path, notice: "Logged out successfully"
    end

    private

    def redirect_if_authenticated
      redirect_to admin_clients_path if session[:user_id].present?
    end
  end
end

