module Admin
  class MyInvoicesController < BaseController
    def index
      @invoices = current_user.invoices.includes(:invoice_items, :invoice_payments).order(created_at: :desc)
      @commission_invoices = current_user.commission_invoices.order(created_at: :desc)
      
      @pending_invoices = @invoices.where(status: %w[pending partial])
      @paid_invoices = @invoices.where(status: 'paid')
      
      @pending_commission_invoices = @commission_invoices.unpaid
      @paid_commission_invoices = @commission_invoices.paid
      
      @total_pending = @pending_invoices.sum(:balance_due) + @pending_commission_invoices.sum(:total_amount)
      @total_paid = @paid_invoices.sum(:total_amount) + @paid_commission_invoices.sum(:total_amount)
    end
    
    def show
      @invoice = current_user.invoices.find(params[:id])
    end
  end
end

