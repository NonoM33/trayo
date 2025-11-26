module Admin
  class InvoicePaymentsController < BaseController
    before_action :set_invoice

    def create
      amount = params[:amount].to_f
      payment_method = params[:payment_method]
      paid_at = params[:paid_at].present? ? Time.zone.parse(params[:paid_at]) : Time.current
      notes = params[:notes]

      @invoice.register_payment!(
        amount: amount,
        payment_method: payment_method,
        paid_at: paid_at,
        notes: notes,
        recorded_by: current_user
      )

      redirect_back fallback_location: admin_invoice_path(@invoice), notice: "Règlement enregistré"
    rescue StandardError => e
      redirect_back fallback_location: admin_invoice_path(@invoice), alert: "Erreur: #{e.message}"
    end

    private

    def set_invoice
      @invoice = Invoice.find(params[:invoice_id])
    end
  end
end

