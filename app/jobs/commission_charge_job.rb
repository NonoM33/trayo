class CommissionChargeJob < ApplicationJob
  queue_as :default

  def perform(charge_date = Date.current)
    day = charge_date.day
    
    unless [15, 29].include?(day)
      Rails.logger.info "CommissionChargeJob: Not a charge day (#{day}), skipping"
      return
    end

    Rails.logger.info "CommissionChargeJob: Processing charges for #{charge_date}"
    
    CommissionBillingService.charge_pending_invoices(charge_date)
    
    CommissionBillingService.check_overdue_invoices
    
    Rails.logger.info "CommissionChargeJob: Completed for #{charge_date}"
  end
end

