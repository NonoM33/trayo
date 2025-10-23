module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      unless current_user&.is_admin?
        redirect_to root_path, alert: "Access denied"
      end
    end

    def current_user
      return nil unless session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    end
    helper_method :current_user
  end
end

