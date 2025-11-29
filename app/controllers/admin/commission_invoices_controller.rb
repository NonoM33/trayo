module Admin
  class CommissionInvoicesController < BaseController
    def create
      @client = User.find(params[:user_id])
      
      total_profit = params[:total_profit].to_f
      commission_rate = params[:commission_rate].to_f
      commission_amount = params[:commission_amount].to_f
      
      commission_invoice = @client.commission_invoices.create!(
        period_type: 'manual',
        period_start: params[:period_start],
        period_end: params[:period_end],
        total_profit: total_profit,
        commission_rate: commission_rate,
        commission_amount: commission_amount,
        total_amount: commission_amount,
        due_date: params[:due_date],
        notes: params[:notes],
        status: 'pending'
      )

      if params[:update_watermark] == '1'
        @client.mt5_accounts.each do |account|
          account.update!(
            watermark_at_last_billing: account.high_watermark || account.balance
          )
        end
        @client.update!(
          last_watermark_snapshot: @client.mt5_accounts.sum(:high_watermark),
          last_commission_billing_date: Date.current
        )
      end

      invoice = @client.invoices.create!(
        reference: commission_invoice.reference,
        status: 'pending',
        total_amount: commission_amount,
        balance_due: commission_amount
      )

      invoice.add_item(
        label: "Commission sur profits (#{commission_invoice.period_start.strftime('%d/%m')} - #{commission_invoice.period_end.strftime('%d/%m/%Y')})",
        unit_price: commission_amount,
        quantity: 1
      )

      commission_invoice.update!(invoice: invoice)

      @client.update!(commission_balance_due: commission_amount)

      if params[:send_notification] == '1' && @client.phone.present?
        message = "TRAYO: Nouvelle facture commission de #{commission_amount.round(2)}€ créée. Échéance: #{commission_invoice.due_date.strftime('%d/%m/%Y')}."
        SmsService.send_sms(@client.phone, message) rescue nil
      end

      redirect_to admin_client_path(@client, anchor: 'commissions'), notice: "Facture commission créée avec succès (#{commission_invoice.reference})"
    rescue => e
      Rails.logger.error "Failed to create commission invoice: #{e.message}"
      redirect_to admin_client_path(@client), alert: "Erreur: #{e.message}"
    end

    def charge
      @commission_invoice = CommissionInvoice.find(params[:id])
      result = CommissionBillingService.charge_commission(@commission_invoice)
      
      if result[:success]
        redirect_to admin_client_path(@commission_invoice.user), notice: "Paiement effectué avec succès"
      else
        redirect_to admin_client_path(@commission_invoice.user), alert: "Échec du paiement: #{result[:error]}"
      end
    end
  end
end

