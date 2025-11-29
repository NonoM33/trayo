module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      payload = request.body.read
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV['STRIPE_WEBHOOK_SECRET']

      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError => e
        Rails.logger.error "Stripe webhook JSON parse error: #{e.message}"
        render json: { error: 'Invalid payload' }, status: :bad_request
        return
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.error "Stripe webhook signature error: #{e.message}"
        render json: { error: 'Invalid signature' }, status: :bad_request
        return
      end

      Rails.logger.info "Stripe webhook received: #{event.type}"

      case event.type
      when 'payment_intent.succeeded'
        handle_payment_intent_succeeded(event.data.object)
      when 'payment_intent.payment_failed'
        handle_payment_intent_failed(event.data.object)
      when 'checkout.session.completed'
        handle_checkout_session_completed(event.data.object)
      when 'customer.subscription.created'
        handle_subscription_created(event.data.object)
      when 'customer.subscription.updated'
        handle_subscription_updated(event.data.object)
      when 'customer.subscription.deleted'
        handle_subscription_deleted(event.data.object)
      when 'invoice.paid'
        handle_invoice_paid(event.data.object)
      when 'invoice.payment_failed'
        handle_invoice_payment_failed(event.data.object)
      else
        Rails.logger.info "Unhandled Stripe event type: #{event.type}"
      end

      render json: { received: true }
    end

    private

    def handle_payment_intent_succeeded(payment_intent)
      Rails.logger.info "PaymentIntent succeeded: #{payment_intent.id}"
      
      invitation_code = payment_intent.metadata['invitation_code']
      
      if invitation_code.present?
        invitation = Invitation.find_by(code: invitation_code)
        if invitation
          invitation.update(
            broker_data: (invitation.broker_data_parsed || {}).merge(
              payment_status: 'succeeded',
              paid_at: Time.current.iso8601,
              stripe_payment_intent_id: payment_intent.id
            ).to_json
          )
          Rails.logger.info "Invitation #{invitation_code} payment marked as succeeded"
        end
      end

      invoice = Invoice.find_by(stripe_payment_intent_id: payment_intent.id)
      if invoice && invoice.status != 'paid'
        invoice.register_payment!(
          amount: payment_intent.amount / 100.0,
          payment_method: 'stripe',
          paid_at: Time.current,
          notes: "Webhook Stripe: #{payment_intent.id}"
        )
        invoice.update(stripe_charge_id: payment_intent.latest_charge)
        Rails.logger.info "Invoice #{invoice.reference} marked as paid via webhook"
      end
    end

    def handle_payment_intent_failed(payment_intent)
      Rails.logger.warn "PaymentIntent failed: #{payment_intent.id}"
      
      invitation_code = payment_intent.metadata['invitation_code']
      
      if invitation_code.present?
        invitation = Invitation.find_by(code: invitation_code)
        if invitation
          invitation.update(
            broker_data: (invitation.broker_data_parsed || {}).merge(
              payment_status: 'failed',
              failed_at: Time.current.iso8601,
              failure_message: payment_intent.last_payment_error&.message
            ).to_json
          )
        end
      end
    end

    def handle_checkout_session_completed(session)
      Rails.logger.info "Checkout session completed: #{session.id}"
      
      user_id = session.metadata['user_id']
      product_id = session.metadata['product_id']
      
      return unless user_id.present? && product_id.present?
      
      user = User.find_by(id: user_id)
      product = ShopProduct.find_by(id: product_id)
      
      return unless user && product
      
      user.update(stripe_customer_id: session.customer) if session.customer.present?
      
      purchase = user.product_purchases.find_by(shop_product_id: product.id, status: 'pending')
      
      if purchase
        purchase.activate!(
          payment_intent_id: session.payment_intent,
          subscription_id: session.subscription
        )
        Rails.logger.info "Product purchase activated: #{product.name} for user #{user.email}"
      else
        user.product_purchases.create!(
          shop_product: product,
          price_paid: product.price,
          status: 'active',
          starts_at: Time.current,
          expires_at: product.subscription? ? 1.year.from_now : nil,
          stripe_payment_intent_id: session.payment_intent,
          stripe_subscription_id: session.subscription
        )
        Rails.logger.info "New product purchase created: #{product.name} for user #{user.email}"
      end
    end

    def handle_subscription_created(subscription)
      Rails.logger.info "Subscription created: #{subscription.id}"
      
      user = User.find_by(stripe_customer_id: subscription.customer)
      return unless user

      user_subscription = user.subscriptions.find_or_initialize_by(stripe_subscription_id: subscription.id)
      user_subscription.update(
        stripe_customer_id: subscription.customer,
        status: subscription.status,
        plan: subscription.metadata['plan'] || 'pro',
        monthly_price: Subscription::PLANS[subscription.metadata['plan'] || 'pro']&.dig(:price) || 149.99,
        current_period_start: Time.at(subscription.current_period_start),
        current_period_end: Time.at(subscription.current_period_end)
      )
    end

    def handle_subscription_updated(subscription)
      Rails.logger.info "Subscription updated: #{subscription.id}"
      
      user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
      return unless user_subscription

      user_subscription.update(
        status: subscription.status,
        current_period_start: Time.at(subscription.current_period_start),
        current_period_end: Time.at(subscription.current_period_end)
      )

      if subscription.status == 'active'
        user_subscription.user.bot_purchases.where("purchase_type LIKE 'subscription_%'").update_all(status: 'active')
      elsif subscription.status == 'past_due' || subscription.status == 'unpaid'
        user_subscription.user.bot_purchases.where("purchase_type LIKE 'subscription_%'").update_all(status: 'inactive', is_running: false)
      end
    end

    def handle_subscription_deleted(subscription)
      Rails.logger.info "Subscription deleted: #{subscription.id}"
      
      user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
      return unless user_subscription

      user_subscription.update(status: 'canceled', canceled_at: Time.current)
      user_subscription.user.bot_purchases.where("purchase_type LIKE 'subscription_%'").update_all(status: 'inactive', is_running: false)
    end

    def handle_invoice_paid(invoice)
      Rails.logger.info "Stripe invoice paid: #{invoice.id}"
      
      subscription_id = invoice.subscription
      return unless subscription_id

      user_subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
      return unless user_subscription

      user_subscription.update(
        status: 'active',
        current_period_end: Time.at(invoice.lines.data.first&.period&.end || (Time.current + 1.month).to_i)
      )
      
      user_subscription.user.bot_purchases.where("purchase_type LIKE 'subscription_%'").update_all(
        status: 'active',
        billing_status: 'paid'
      )
    end

    def handle_invoice_payment_failed(invoice)
      Rails.logger.warn "Stripe invoice payment failed: #{invoice.id}"
      
      subscription_id = invoice.subscription
      return unless subscription_id

      user_subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
      return unless user_subscription

      user_subscription.update(status: 'past_due')
    end
  end
end
