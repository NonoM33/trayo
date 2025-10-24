class Admin::MaintenanceController < Admin::BaseController
  before_action :require_admin
  
  def show
    @maintenance = MaintenanceSetting.current
  end
  
  def update
    @maintenance = MaintenanceSetting.current
    
    if @maintenance.update(maintenance_params)
      redirect_to admin_maintenance_path, notice: 'Paramètres de maintenance mis à jour avec succès.'
    else
      render :show, status: :unprocessable_entity
    end
  end
  
  def toggle
    @maintenance = MaintenanceSetting.current
    @maintenance.update!(is_enabled: !@maintenance.is_enabled?)
    
    redirect_to admin_maintenance_path, notice: @maintenance.is_enabled? ? 'Mode maintenance activé' : 'Mode maintenance désactivé'
  end
  
  private
  
  def maintenance_params
    params.require(:maintenance_setting).permit(:is_enabled, :logo_url, :title, :subtitle, :description, :countdown_date)
  end
end
