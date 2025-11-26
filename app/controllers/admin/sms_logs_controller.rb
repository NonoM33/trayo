module Admin
  class SmsLogsController < BaseController
    def index
      @logs = CommissionReminder.includes(:user).order(created_at: :desc).page(params[:page]).per(50)
    end
  end
end

