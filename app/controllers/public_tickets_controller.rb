class PublicTicketsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:add_comment]

  def show
    @ticket = SupportTicket.find_by(public_token: params[:token])
    
    unless @ticket
      redirect_to root_path, alert: "Ticket introuvable."
      return
    end

    @comments = @ticket.public_comments
  end

  def add_comment
    @ticket = SupportTicket.find_by(public_token: params[:token])
    
    unless @ticket
      redirect_to root_path, alert: "Ticket introuvable."
      return
    end

    @comment = @ticket.ticket_comments.build(
      content: params[:content],
      is_internal: false,
      author_name: params[:name] || "Client",
      author_email: params[:email] || @ticket.phone_number
    )

    if @comment.save
      # Notifier les admins
      notify_admins_new_comment(@ticket, @comment)
      redirect_to ticket_path(@ticket.public_token), notice: "Votre commentaire a été ajouté."
    else
      redirect_to ticket_path(@ticket.public_token), alert: "Erreur lors de l'ajout du commentaire."
    end
  end

  private

  def notify_admins_new_comment(ticket, comment)
    # TODO: Implémenter une notification (email, SMS, etc.)
    Rails.logger.info("[PublicTickets] New comment on ticket #{ticket.ticket_number} by #{comment.author_display_name}")
  end
end

