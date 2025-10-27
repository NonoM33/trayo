module Admin
  class InvitationsController < BaseController
    before_action :require_admin
    
    def index
      @invitations = Invitation.order(created_at: :desc).page(params[:page]).per(20)
    end
    
    def new
      @invitation = Invitation.new
    end
    
    def create
      @invitation = Invitation.new(invitation_params)
      @invitation.code = Invitation.generate_unique_code
      @invitation.expires_at = 30.days.from_now unless @invitation.expires_at
      
      if @invitation.save
        redirect_to admin_invitation_path(@invitation), notice: "Invitation créée avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def show
      @invitation = Invitation.find(params[:id])
    end
    
    def destroy
      @invitation = Invitation.find(params[:id])
      @invitation.destroy
      
      redirect_to admin_invitations_path, notice: "Invitation supprimée"
    end
    
    private
    
    def invitation_params
      params.require(:invitation).permit(:expires_at)
    end
  end
end
