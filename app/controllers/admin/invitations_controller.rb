module Admin
  class InvitationsController < BaseController
    before_action :require_admin
    
    def create
      @invitation = Invitation.new(invitation_params)
      @invitation.code = Invitation.generate_unique_code
      @invitation.expires_at = 30.days.from_now unless @invitation.expires_at
      
      if @invitation.save
        redirect_to admin_clients_path, notice: "Invitation créée ! Code: #{@invitation.code}"
      else
        redirect_to admin_clients_path, alert: "Erreur lors de la création de l'invitation"
      end
    end
    
    def destroy
      @invitation = Invitation.find(params[:id])
      @invitation.destroy
      
      redirect_to admin_clients_path, notice: "Invitation supprimée"
    end
    
    private
    
    def invitation_params
      params.require(:invitation).permit(:expires_at)
    end
  end
end
