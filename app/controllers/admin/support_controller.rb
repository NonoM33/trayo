class Admin::SupportController < Admin::BaseController
  before_action :require_admin

  def index
    @tab = params[:tab] || 'tickets'
    
    case @tab
    when 'tickets'
      load_tickets
    when 'sms'
      load_sms
    end
  end

  private

  def load_tickets
    tickets = SupportTicket.includes(:user).order(created_at: :desc)
    tickets = tickets.where(status: params[:status]) if params[:status].present?
    tickets = tickets.where(ticket_number: params[:ticket_number]) if params[:ticket_number].present?
    tickets = tickets.where(phone_number: params[:phone]) if params[:phone].present?
    
    @tickets = tickets.page(params[:page]).per(25)
    @stats = {
      total: SupportTicket.count,
      open: SupportTicket.where(status: 'open').count,
      closed: SupportTicket.where(status: 'closed').count,
      unread: SupportTicket.unread.count
    }
  end

  def load_sms
    @logs = CommissionReminder.includes(:user).order(created_at: :desc).page(params[:page]).per(50)
    @sms_stats = {
      total: CommissionReminder.count,
      sent: CommissionReminder.where(status: 'sent').count,
      pending: CommissionReminder.where(status: 'pending').count,
      failed: CommissionReminder.where(status: 'failed').count
    }
  end
end

