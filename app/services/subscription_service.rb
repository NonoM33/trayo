class SubscriptionService
  class << self
    def create_subscription(user:, plan:, payment_method_id:)
      plan_config = Subscription::PLANS[plan]
      raise ArgumentError, "Invalid plan: #{plan}" unless plan_config

      customer = find_or_create_customer(user, payment_method_id)

      stripe_price_id = get_or_create_price(plan, plan_config)

      subscription = Stripe::Subscription.create(
        customer: customer.id,
        items: [{ price: stripe_price_id }],
        default_payment_method: payment_method_id,
        payment_behavior: 'default_incomplete',
        payment_settings: { save_default_payment_method: 'on_subscription' },
        expand: ['latest_invoice.payment_intent'],
        metadata: {
          user_id: user.id,
          plan: plan
        }
      )

      user.update!(stripe_customer_id: customer.id)

local_subscription = Subscription.create!(
      user: user,
      stripe_subscription_id: subscription.id,
      stripe_customer_id: customer.id,
      plan: plan,
      status: subscription.status,
      monthly_price: plan_config[:price],
      current_period_start: Time.at(subscription.current_period_start),
      current_period_end: Time.at(subscription.current_period_end)
    )

    create_subscription_invoice(user, local_subscription, subscription)

    {
      subscription: local_subscription,
      stripe_subscription: subscription,
      client_secret: subscription.latest_invoice&.payment_intent&.client_secret
    }
    end

    def handle_payment_succeeded(invoice)
      subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
      return unless subscription

      subscription.update!(
        status: 'active',
        failed_payment_count: 0,
        last_payment_failed_at: nil
      )

      subscription.sync_from_stripe!

      if invoice.billing_reason == 'subscription_cycle'
        create_renewal_invoice(subscription, invoice)
      end

      Rails.logger.info "Subscription #{subscription.id} payment succeeded"
    end

    def handle_payment_failed(invoice)
      subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
      return unless subscription

      subscription.update!(
        status: 'past_due',
        failed_payment_count: subscription.failed_payment_count + 1,
        last_payment_failed_at: Time.current
      )

      notify_admin_payment_failed(subscription, invoice)

      SubscriptionReminderJob.set(wait: 24.hours).perform_later(subscription.id)

      Rails.logger.warn "Subscription #{subscription.id} payment failed (count: #{subscription.failed_payment_count})"
    end

    def handle_subscription_updated(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      subscription.update!(
        status: stripe_subscription.status,
        current_period_start: Time.at(stripe_subscription.current_period_start),
        current_period_end: Time.at(stripe_subscription.current_period_end),
        canceled_at: stripe_subscription.canceled_at ? Time.at(stripe_subscription.canceled_at) : nil
      )

      if stripe_subscription.status == 'canceled'
        deactivate_user_services(subscription.user)
      end
    end

    def handle_subscription_deleted(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      subscription.update!(
        status: 'canceled',
        canceled_at: Time.current
      )

      deactivate_user_services(subscription.user)
    end

    def send_payment_reminder(subscription)
      return unless subscription.past_due?
      return if subscription.last_reminder_sent_at && subscription.last_reminder_sent_at > 12.hours.ago

      user = subscription.user

      if user.phone.present?
        send_sms_reminder(user, subscription)
      end

      notify_admin_reminder_sent(subscription)

      subscription.update!(last_reminder_sent_at: Time.current)
    end

    def check_and_cancel_unpaid_subscriptions
      Subscription.past_due.where('failed_payment_count >= ?', 3).find_each do |subscription|
        subscription.cancel_subscription!(reason: 'Trop de paiements échoués')
        notify_admin_subscription_canceled(subscription)
      end
    end

    private

    def find_or_create_customer(user, payment_method_id)
      if user.stripe_customer_id.present?
        begin
          customer = Stripe::Customer.retrieve(user.stripe_customer_id)
          if payment_method_id.present?
            Stripe::PaymentMethod.attach(payment_method_id, customer: customer.id)
            Stripe::Customer.update(customer.id, invoice_settings: { default_payment_method: payment_method_id })
          end
          return customer
        rescue Stripe::InvalidRequestError => e
          Rails.logger.warn "Customer not found, creating new: #{e.message}"
        end
      end

      Stripe::Customer.create(
        email: user.email,
        name: user.full_name,
        phone: user.phone,
        payment_method: payment_method_id,
        invoice_settings: { default_payment_method: payment_method_id },
        metadata: { user_id: user.id }
      )
    end

    def get_or_create_price(plan, plan_config)
      return plan_config[:stripe_price_id] if plan_config[:stripe_price_id].present?

      product = Stripe::Product.create(
        name: "Trayo #{plan_config[:name]}",
        description: "Abonnement mensuel #{plan_config[:name]}",
        metadata: { plan: plan }
      )

      price = Stripe::Price.create(
        product: product.id,
        unit_amount: (plan_config[:price] * 100).to_i,
        currency: 'eur',
        recurring: { interval: 'month' },
        metadata: { plan: plan }
      )

      Rails.logger.info "Created Stripe price #{price.id} for plan #{plan}"
      price.id
    end

    def send_sms_reminder(user, subscription)
      message = <<~SMS.squish
        Bonjour #{user.first_name}, votre paiement Trayo de #{subscription.monthly_price}€ a échoué.
        Mettez à jour votre moyen de paiement pour éviter l'interruption du service.
        Merci de votre confiance.
      SMS

      SmsService.send_sms(to: user.phone, message: message)
      Rails.logger.info "SMS reminder sent to #{user.phone} for subscription #{subscription.id}"
    rescue => e
      Rails.logger.error "Failed to send SMS reminder: #{e.message}"
    end

    def notify_admin_payment_failed(subscription, invoice)
      user = subscription.user
      
      admin_message = <<~MSG
        ⚠️ ALERTE PAIEMENT ÉCHOUÉ
        
        Client: #{user.full_name} (#{user.email})
        Plan: #{subscription.plan_name}
        Montant: #{subscription.monthly_price}€
        Échecs: #{subscription.failed_payment_count}
        
        Action requise sous 24h.
      MSG

      AdminNotificationService.notify(
        title: "Paiement échoué - #{user.full_name}",
        message: admin_message,
        level: :warning,
        metadata: {
          subscription_id: subscription.id,
          user_id: user.id,
          invoice_id: invoice.id
        }
      )
    rescue => e
      Rails.logger.error "Failed to notify admin: #{e.message}"
    end

    def notify_admin_reminder_sent(subscription)
      user = subscription.user
      
      AdminNotificationService.notify(
        title: "Relance envoyée - #{user.full_name}",
        message: "SMS de relance envoyé au client #{user.full_name} pour l'abonnement #{subscription.plan_name}",
        level: :info,
        metadata: { subscription_id: subscription.id }
      )
    rescue => e
      Rails.logger.error "Failed to notify admin: #{e.message}"
    end

    def notify_admin_subscription_canceled(subscription)
      user = subscription.user
      
      AdminNotificationService.notify(
        title: "Abonnement annulé - #{user.full_name}",
        message: "L'abonnement #{subscription.plan_name} de #{user.full_name} a été annulé suite à 3 paiements échoués.",
        level: :error,
        metadata: { subscription_id: subscription.id }
      )
    rescue => e
      Rails.logger.error "Failed to notify admin: #{e.message}"
    end

    def deactivate_user_services(user)
      user.bot_purchases.where(purchase_type: ['subscription_starter', 'subscription_pro', 'subscription_premium']).update_all(
        is_running: false,
        status: 'suspended'
      )
      
      Rails.logger.info "Deactivated services for user #{user.id} due to subscription cancellation"
    end

    def create_subscription_invoice(user, local_subscription, stripe_subscription)
      invoice = user.invoices.create!(
        reference: "INV-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}",
        status: 'paid',
        total_amount: local_subscription.monthly_price,
        balance_due: 0,
        stripe_payment_intent_id: stripe_subscription.latest_invoice&.payment_intent
      )

      invoice.invoice_items.create!(
        label: "Abonnement #{local_subscription.plan_name} (mensuel)",
        unit_price: local_subscription.monthly_price,
        quantity: 1,
        total_price: local_subscription.monthly_price,
        item_type: 'subscription',
        metadata: { subscription_id: local_subscription.id, plan: local_subscription.plan }.to_json
      )

      invoice.invoice_payments.create!(
        amount: local_subscription.monthly_price,
        payment_method: 'stripe_subscription',
        paid_at: Time.current,
        notes: "Abonnement #{local_subscription.plan_name} - Premier paiement"
      )

      Rails.logger.info "Created invoice #{invoice.reference} for subscription #{local_subscription.id}"
      invoice
    rescue => e
      Rails.logger.error "Failed to create subscription invoice: #{e.message}"
      nil
    end

    def create_renewal_invoice(subscription, stripe_invoice)
      user = subscription.user
      
      invoice = user.invoices.create!(
        reference: "INV-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}",
        status: 'paid',
        total_amount: subscription.monthly_price,
        balance_due: 0,
        stripe_payment_intent_id: stripe_invoice.payment_intent
      )

      invoice.invoice_items.create!(
        label: "Abonnement #{subscription.plan_name} - Renouvellement",
        unit_price: subscription.monthly_price,
        quantity: 1,
        total_price: subscription.monthly_price,
        item_type: 'subscription_renewal',
        metadata: { subscription_id: subscription.id, stripe_invoice_id: stripe_invoice.id }.to_json
      )

      invoice.invoice_payments.create!(
        amount: subscription.monthly_price,
        payment_method: 'stripe_subscription',
        paid_at: Time.current,
        notes: "Renouvellement abonnement #{subscription.plan_name}"
      )

      Rails.logger.info "Created renewal invoice #{invoice.reference} for subscription #{subscription.id}"
      invoice
    rescue => e
      Rails.logger.error "Failed to create renewal invoice: #{e.message}"
      nil
    end
  end
end

