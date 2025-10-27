module Admin
  class VpsController < BaseController
    before_action :require_admin, except: [:index, :show]
    before_action :set_vps, only: [:show, :edit, :update, :destroy, :update_status]

    def index
      if current_user.is_admin?
        @vps_list = Vps.includes(:user).recent
      else
        @vps_list = current_user.vps.recent
      end
    end

    def show
      unless current_user.is_admin? || @vps.user_id == current_user.id
        redirect_to admin_vps_path, alert: "Accès refusé"
      end
    end

    def new
      @vps = Vps.new
      @vps.user_id = params[:user_id] if params[:user_id].present?
      @clients = User.where(is_admin: false).order(:email)
    end

    def create
      @vps = Vps.new(vps_params)
      @vps.ordered_at = Time.current
      
      if @vps.save
        if params[:redirect_to_client] == 'true' || request.referer&.include?('/clients/')
          redirect_to admin_client_path(@vps.user), notice: "VPS créé avec succès"
        else
          redirect_to admin_vps_path, notice: "VPS créé avec succès"
        end
      else
        @clients = User.where(is_admin: false).order(:email)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @clients = User.where(is_admin: false).order(:email)
    end

    def update
      if @vps.update(vps_params)
        redirect_to admin_vps_path(@vps), notice: "VPS mis à jour avec succès"
      else
        @clients = User.where(is_admin: false).order(:email)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @vps.destroy
      redirect_to admin_vps_path, notice: "VPS supprimé avec succès"
    end

    def update_status
      new_status = params[:new_status]
      
      case new_status
      when 'configuring'
        @vps.mark_as_configuring!
      when 'ready'
        @vps.mark_as_ready!
      when 'active'
        @vps.mark_as_active!
      when 'suspended'
        @vps.suspend!
      when 'cancelled'
        @vps.cancel!
      else
        @vps.update(status: new_status)
      end
      
      redirect_to admin_vps_path(@vps), notice: "Statut mis à jour : #{@vps.status_label}"
    end

    private

    def set_vps
      @vps = Vps.find(params[:id])
    end

    def vps_params
      params.require(:vps).permit(
        :user_id, :name, :ip_address, :server_location,
        :status, :monthly_price, :access_credentials, :notes, :renewal_date
      )
    end
  end
end

