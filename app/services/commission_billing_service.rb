class CommissionBillingService
  class << self
    def create_invoices_for_period(billing_date = Date.current)
      period_type = billing_date.day == 14 ? 'first_half' : 'second_half'
      
      User.where(commission_billing_enabled: true)
          .joins(:mt5_accounts)
          .distinct
          .find_each do |user|
        create_commission_invoice(user, period_type, billing_date)
      end
    end

    def create_commission_invoice(user, period_type, billing_date)
      period_start, period_end = calculate_period_dates(period_type, billing_date)
      
      total_profit = calculate_profit_for_period(user, period_start, period_end)
      
      return if total_profit <= 0

      commission_rate = user.commission_rate || 25.0
      commission_amount = (total_profit * commission_rate / 100.0).round(2)
      
      return if commission_amount < 1.0

      due_date = period_type == 'first_half' ? 
        Date.new(billing_date.year, billing_date.month, 15) : 
        Date.new(billing_date.year, billing_date.month, 29)

      commission_invoice = user.commission_invoices.create!(
        period_type: period_type,
        period_start: period_start,
        period_end: period_end,
        total_profit: total_profit,
        commission_rate: commission_rate,
        commission_amount: commission_amount,
        total_amount: commission_amount,
        due_date: due_date,
        status: 'pending'
      )

      snapshot_watermarks(user)

      user.update!(
        last_commission_billing_date: billing_date,
        commission_balance_due: commission_amount
      )

      create_linked_invoice(user, commission_invoice)

      Rails.logger.info "Created commission invoice #{commission_invoice.reference} for user #{user.id}: #{commission_amount}€"
      
      commission_invoice
    rescue => e
      Rails.logger.error "Failed to create commission invoice for user #{user.id}: #{e.message}"
      nil
    end

    def charge_pending_invoices(charge_date = Date.current)
      CommissionInvoice.where(status: %w[pending reminder_sent])
                       .where(due_date: charge_date.all_day)
                       .find_each do |commission_invoice|
        charge_commission(commission_invoice)
      end
    end

    def charge_commission(commission_invoice)
      user = commission_invoice.user
      
      unless user.stripe_customer_id.present?
        commission_invoice.mark_as_failed!
        send_payment_failure_notification(commission_invoice)
        return { success: false, error: 'No Stripe customer' }
      end

      begin
        payment_intent = Stripe::PaymentIntent.create({
          amount: (commission_invoice.total_amount * 100).to_i,
          currency: 'eur',
          customer: user.stripe_customer_id,
          confirm: true,
          off_session: true,
          description: "Commission TRAYO - #{commission_invoice.reference}",
          metadata: {
            commission_invoice_id: commission_invoice.id,
            user_id: user.id,
            period: "#{commission_invoice.period_start} - #{commission_invoice.period_end}"
          }
        })

        if payment_intent.status == 'succeeded'
          commission_invoice.mark_as_paid!(payment_intent.id)
          Rails.logger.info "Commission charged successfully: #{commission_invoice.reference}"
          { success: true, payment_intent: payment_intent }
        else
          commission_invoice.mark_as_failed!
          send_payment_failure_notification(commission_invoice)
          { success: false, error: 'Payment not succeeded', status: payment_intent.status }
        end
      rescue Stripe::CardError => e
        commission_invoice.mark_as_failed!
        send_payment_failure_notification(commission_invoice)
        Rails.logger.error "Stripe card error for #{commission_invoice.reference}: #{e.message}"
        { success: false, error: e.message }
      rescue Stripe::StripeError => e
        commission_invoice.mark_as_failed!
        send_payment_failure_notification(commission_invoice)
        Rails.logger.error "Stripe error for #{commission_invoice.reference}: #{e.message}"
        { success: false, error: e.message }
      end
    end

    def send_reminders(reminder_date = Date.current)
      due_date = reminder_date + 1.day
      
      CommissionInvoice.pending
                       .where(due_date: due_date.all_day)
                       .where(reminder_sent_at: nil)
                       .find_each do |commission_invoice|
        commission_invoice.send_reminder!
      end
    end

    def check_overdue_invoices
      CommissionInvoice.where(status: %w[failed])
                       .find_each do |commission_invoice|
        if commission_invoice.should_apply_late_fee?
          commission_invoice.mark_as_overdue!
          Rails.logger.warn "Applied late fee to commission invoice #{commission_invoice.reference}"
        end
      end
    end

    def calculate_user_performance(user)
      accounts = user.mt5_accounts
      
      return default_performance if accounts.empty?

      total_balance = accounts.sum(:balance)
      total_initial = accounts.sum { |a| a.initial_balance_snapshot || a.initial_balance || 0 }
      total_high_watermark = accounts.sum(:high_watermark)
      total_profit = total_balance - total_initial
      
      first_trade_date = Trade.joins(:mt5_account)
                              .where(mt5_accounts: { user_id: user.id })
                              .minimum(:close_time)
      
      days_trading = first_trade_date ? (Date.current - first_trade_date.to_date).to_i : 1
      days_trading = [days_trading, 1].max

      daily_avg = days_trading > 0 ? (total_profit / days_trading).round(2) : 0
      
      pending_commission = calculate_pending_commission(user)
      
      {
        total_balance: total_balance.round(2),
        initial_balance: total_initial.round(2),
        high_watermark: total_high_watermark.round(2),
        total_profit: total_profit.round(2),
        total_profit_percent: total_initial > 0 ? ((total_profit / total_initial) * 100).round(2) : 0,
        days_trading: days_trading,
        daily_average: daily_avg,
        commission_rate: user.commission_rate || 25.0,
        pending_commission: pending_commission.round(2),
        commission_due: user.commission_balance_due || 0
      }
    end

    private

    def calculate_period_dates(period_type, billing_date)
      if period_type == 'first_half'
        period_start = Date.new(billing_date.year, billing_date.month, 1)
        period_end = Date.new(billing_date.year, billing_date.month, 14)
      else
        period_start = Date.new(billing_date.year, billing_date.month, 15)
        period_end = billing_date.end_of_month < Date.new(billing_date.year, billing_date.month, 28) ? 
                     billing_date.end_of_month : 
                     Date.new(billing_date.year, billing_date.month, 28)
      end
      [period_start, period_end]
    end

    def calculate_profit_for_period(user, period_start, period_end)
      user.mt5_accounts.sum do |account|
        last_watermark = account.watermark_at_last_billing || account.initial_balance || 0
        current_balance = account.balance || 0
        
        profit = current_balance - last_watermark
        [profit, 0].max
      end
    end

    def calculate_pending_commission(user)
      user.mt5_accounts.sum do |account|
        last_watermark = account.watermark_at_last_billing || account.high_watermark || account.initial_balance || 0
        current_balance = account.balance || 0
        profit = [current_balance - last_watermark, 0].max
        profit * (user.commission_rate || 25.0) / 100.0
      end
    end

    def snapshot_watermarks(user)
      user.mt5_accounts.each do |account|
        account.update!(
          watermark_at_last_billing: account.high_watermark || account.balance,
          initial_balance_snapshot: account.initial_balance_snapshot || account.initial_balance
        )
      end
      
      user.update!(last_watermark_snapshot: user.mt5_accounts.sum(:high_watermark))
    end

    def create_linked_invoice(user, commission_invoice)
      invoice = user.invoices.create!(
        reference: commission_invoice.reference,
        status: 'pending',
        total_amount: commission_invoice.total_amount,
        balance_due: commission_invoice.total_amount
      )

      invoice.add_item(
        label: "Commission sur profits (#{commission_invoice.period_start.strftime('%d/%m')} - #{commission_invoice.period_end.strftime('%d/%m/%Y')})",
        unit_price: commission_invoice.commission_amount,
        quantity: 1
      )

      if commission_invoice.late_fee > 0
        invoice.add_item(
          label: "Frais de remise en route",
          unit_price: commission_invoice.late_fee,
          quantity: 1
        )
      end

      commission_invoice.update!(invoice: invoice)
      invoice
    end

    def send_payment_failure_notification(commission_invoice)
      commission_invoice.send_payment_link!
      
      AdminNotificationService.notify_admin(
        "Échec prélèvement commission #{commission_invoice.reference} pour #{commission_invoice.user.email} (#{commission_invoice.total_amount}€)",
        type: :error
      )
    end

    def default_performance
      {
        total_balance: 0,
        initial_balance: 0,
        high_watermark: 0,
        total_profit: 0,
        total_profit_percent: 0,
        days_trading: 0,
        daily_average: 0,
        commission_rate: 25.0,
        pending_commission: 0,
        commission_due: 0
      }
    end
  end
end

