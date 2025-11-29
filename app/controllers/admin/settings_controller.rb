class Admin::SettingsController < Admin::BaseController
  before_action :require_admin

  def index
    @tab = params[:tab] || 'maintenance'
    
    case @tab
    when 'maintenance'
      @maintenance = MaintenanceSetting.first_or_create
    when 'backups'
      @backups = DatabaseBackup.order(created_at: :desc)
    end
  end
end

