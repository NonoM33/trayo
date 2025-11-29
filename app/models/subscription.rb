class Subscription < ApplicationRecord
  PLANS = {
    'starter' => { name: 'Starter', price: 99.00, stripe_price_id: ENV.fetch('STRIPE_PRICE_STARTER', nil) },
    'pro' => { name: 'Pro', price: 149.99, stripe_price_id: ENV.fetch('STRIPE_PRICE_PRO', nil) },
    'premium' => { name: 'Premium', price: 299.99, stripe_price_id: ENV.fetch('STRIPE_PRICE_PREMIUM', nil) }
  }.freeze

  STATUSES = %w[active past_due canceled unpaid incomplete incomplete_expired trialing paused].freeze

  belongs_to :user

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_customer_id, presence: true
  validates :plan, presence: true, inclusion: { in: PLANS.keys }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: 'active') }
  scope :past_due, -> { where(status: 'past_due') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :needs_reminder, -> { 
    past_due
      .where('last_payment_failed_at < ?', 24.hours.ago)
      .where('last_reminder_sent_at IS NULL OR last_reminder_sent_at < ?', 24.hours.ago)
  }

  def plan_details
    PLANS[plan] || {}
  end

  def plan_name
    plan_details[:name] || plan.titleize
  end

  def active?
    status == 'active'
  end

  def past_due?
    status == 'past_due'
  end

  def canceled?
    status == 'canceled'
  end

  def can_use_service?
    %w[active past_due trialing].include?(status)
  end

  def days_until_renewal
    return nil unless current_period_end
    (current_period_end.to_date - Date.current).to_i
  end

  def cancel_subscription!(reason: nil)
    return if canceled?

    begin
      Stripe::Subscription.cancel(stripe_subscription_id)
      update!(
        status: 'canceled',
        canceled_at: Time.current,
        cancellation_reason: reason
      )
      true
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to cancel subscription: #{e.message}"
      false
    end
  end

  def pause_subscription!
    begin
      Stripe::Subscription.update(
        stripe_subscription_id,
        pause_collection: { behavior: 'void' }
      )
      update!(status: 'paused')
      true
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to pause subscription: #{e.message}"
      false
    end
  end

  def resume_subscription!
    begin
      Stripe::Subscription.update(
        stripe_subscription_id,
        pause_collection: ''
      )
      update!(status: 'active')
      true
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to resume subscription: #{e.message}"
      false
    end
  end

  def sync_from_stripe!
    begin
      stripe_sub = Stripe::Subscription.retrieve(stripe_subscription_id)
      update!(
        status: stripe_sub.status,
        current_period_start: Time.at(stripe_sub.current_period_start),
        current_period_end: Time.at(stripe_sub.current_period_end),
        canceled_at: stripe_sub.canceled_at ? Time.at(stripe_sub.canceled_at) : nil
      )
      true
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to sync subscription: #{e.message}"
      false
    end
  end

  def self.create_for_user!(user:, plan:, payment_method_id:)
    plan_config = PLANS[plan]
    raise ArgumentError, "Invalid plan: #{plan}" unless plan_config
    raise ArgumentError, "Stripe price ID not configured for plan: #{plan}" unless plan_config[:stripe_price_id]

    customer = find_or_create_stripe_customer(user, payment_method_id)
    
    subscription = Stripe::Subscription.create(
      customer: customer.id,
      items: [{ price: plan_config[:stripe_price_id] }],
      default_payment_method: payment_method_id,
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent']
    )

    user.update!(stripe_customer_id: customer.id)

    create!(
      user: user,
      stripe_subscription_id: subscription.id,
      stripe_customer_id: customer.id,
      plan: plan,
      status: subscription.status,
      monthly_price: plan_config[:price],
      current_period_start: Time.at(subscription.current_period_start),
      current_period_end: Time.at(subscription.current_period_end)
    )
  end

  def self.find_or_create_stripe_customer(user, payment_method_id)
    if user.stripe_customer_id.present?
      begin
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
        Stripe::PaymentMethod.attach(payment_method_id, customer: customer.id)
        return customer
      rescue Stripe::InvalidRequestError
      end
    end

    customer = Stripe::Customer.create(
      email: user.email,
      name: user.full_name,
      phone: user.phone,
      payment_method: payment_method_id,
      invoice_settings: { default_payment_method: payment_method_id },
      metadata: { user_id: user.id }
    )

    customer
  end
end

