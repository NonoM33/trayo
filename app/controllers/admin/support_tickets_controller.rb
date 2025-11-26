module Admin
  class SupportTicketsController < BaseController
    before_action :ensure_admin
    before_action :set_ticket, only: [:show, :update, :destroy, :mark_as_read, :add_comment]

    def index
      @tickets = SupportTicket.includes(:user).recent
      
      # Filtres
      @tickets = @tickets.where(status: params[:status]) if params[:status].present?
      @tickets = @tickets.where("phone_number LIKE ?", "%#{params[:phone]}%") if params[:phone].present?
      @tickets = @tickets.where("ticket_number LIKE ?", "%#{params[:ticket_number]}%") if params[:ticket_number].present?
      @tickets = @tickets.where(user_id: params[:user_id]) if params[:user_id].present?
      
      # Pagination
      @tickets = @tickets.page(params[:page]).per(20)
      
      # Statistiques
      @stats = {
        total: SupportTicket.count,
        open: SupportTicket.open.count,
        closed: SupportTicket.closed.count,
        unread: SupportTicket.unread.count
      }
    end

    def show
      @ticket.update(read_at: Time.current) if @ticket.read_at.nil?
      @comments = @ticket.ticket_comments.recent
    end

    def update
      old_status = @ticket.status
      
      if @ticket.update(ticket_params)
        # Créer un commentaire automatique si le statut a changé
        if old_status != @ticket.status && params[:status_change_comment].present?
          @ticket.ticket_comments.create!(
            user: current_user,
            content: "Statut changé de #{SupportTicket.new(status: old_status).status_label} à #{@ticket.status_label}. #{params[:status_change_comment]}",
            is_internal: false
          )
        end
        
        redirect_to admin_support_ticket_path(@ticket), notice: "Ticket mis à jour avec succès."
      else
        render :show, alert: "Erreur lors de la mise à jour."
      end
    end

    def add_comment
      @ticket = SupportTicket.find(params[:id])
      
      @comment = @ticket.ticket_comments.build(
        user: current_user,
        content: params[:comment][:content],
        is_internal: params[:comment][:is_internal] == "1"
      )

      if @comment.save
        redirect_to admin_support_ticket_path(@ticket), notice: "Commentaire ajouté."
      else
        redirect_to admin_support_ticket_path(@ticket), alert: "Erreur lors de l'ajout du commentaire."
      end
    end

    def mark_as_read
      @ticket.update(read_at: Time.current)
      redirect_to admin_support_tickets_path, notice: "Ticket marqué comme lu."
    end

    def destroy
      @ticket.destroy
      redirect_to admin_support_tickets_path, notice: "Ticket supprimé."
    end

    private

    def set_ticket
      @ticket = SupportTicket.find(params[:id])
    end

    def ticket_params
      params.require(:support_ticket).permit(:status, :subject, :description)
    end

    def ensure_admin
      redirect_to admin_dashboard_path, alert: "Accès réservé aux administrateurs." unless current_user.is_admin?
    end
  end
end

