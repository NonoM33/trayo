class MaintenanceController < ApplicationController
  def show
    @maintenance = MaintenanceSetting.current
    
    unless @maintenance.is_enabled?
      redirect_to root_path
      return
    end
    
    render layout: 'admin'
  end
end
