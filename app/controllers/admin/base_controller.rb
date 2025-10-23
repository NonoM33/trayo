module Admin
  class BaseController < ApplicationController
    before_action :require_login

    private

    def require_login
      unless current_user
        redirect_to admin_login_path, alert: "Please login to continue"
      end
    end

    def require_admin
      unless current_user&.is_admin?
        redirect_to admin_client_path(current_user), alert: "Access denied. Admin privileges required."
      end
    end

    def current_user
      return nil unless session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    end
    helper_method :current_user
  end
end

