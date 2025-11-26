module Admin
  class InvoicesController < BaseController
    before_action :set_invoice, only: [:show]

    def index
      @invoices = Invoice.includes(:user).order(created_at: :desc).page(params[:page]).per(25)
    end

    def show; end

    def create
      user = nil
      user = User.find(invoice_params[:user_id])

      bot_ids = Array(params[:bot_purchase_ids]).reject(&:blank?)
      vps_ids = Array(params[:vps_ids]).reject(&:blank?)

      if bot_ids.empty? && vps_ids.empty?
        redirect_back fallback_location: admin_client_path(user), alert: "Sélectionne au moins un bot ou un VPS"
        return
      end

      bot_purchases = user.bot_purchases.where(id: bot_ids, invoice_id: nil)
      vps_list = user.vps.where(id: vps_ids, invoice_id: nil)

      builder = Invoices::Builder.new(
        user: user,
        source: "manual",
        metadata: { created_by: current_user.id },
        deactivate_bots: false,
        due_date: parsed_due_date
      )

      invoice = builder.build_from_selection(
        bot_purchases: bot_purchases,
        vps_list: vps_list
      )

      redirect_to admin_invoice_path(invoice), notice: "Facture créée"
    rescue StandardError => e
      fallback = user ? admin_client_path(user) : admin_clients_path
      redirect_back fallback_location: fallback, alert: "Erreur facture : #{e.message}"
    end

    private

    def set_invoice
      @invoice = Invoice.find(params[:id])
    end

    def invoice_params
      params.permit(:user_id, :due_date)
    end

    def parsed_due_date
      return nil if params[:due_date].blank?

      Date.parse(params[:due_date])
    rescue ArgumentError
      nil
    end
  end
end

