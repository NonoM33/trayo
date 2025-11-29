class CommissionInvoiceJob < ApplicationJob
  queue_as :default

  def perform(billing_date = Date.current)
    day = billing_date.day
    
    unless [14, 28].include?(day)
      Rails.logger.info "CommissionInvoiceJob: Not a billing day (#{day}), skipping"
      return
    end

    Rails.logger.info "CommissionInvoiceJob: Creating commission invoices for #{billing_date}"
    
    CommissionBillingService.create_invoices_for_period(billing_date)
    CommissionBillingService.send_reminders(billing_date)
    
    Rails.logger.info "CommissionInvoiceJob: Completed for #{billing_date}"
  end
end

