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
        redirect_to admin_vps_path, notice: "VPS mis à jour avec succès"
      else
        @clients = User.where(is_admin: false).order(:email)
        redirect_to admin_vps_path, alert: "Erreur lors de la mise à jour"
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
      
      message = "Statut VPS: #{@vps.status_label}"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("vps_#{@vps.id}", partial: "admin/clients/vps_card", locals: { vps: @vps }),
            turbo_stream.replace("flash_messages", partial: "shared/flash_toast", locals: { message: message, type: :success })
          ]
        end
        format.html { redirect_back fallback_location: admin_vps_path, notice: message }
      end
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

