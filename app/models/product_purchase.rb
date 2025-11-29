class ProductPurchase < ApplicationRecord
  STATUSES = %w[pending active expired canceled].freeze

  belongs_to :user
  belongs_to :shop_product

  validates :price_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: 'active') }
  scope :pending, -> { where(status: 'pending') }
  scope :expired, -> { where(status: 'expired') }

  def active?
    status == 'active' && (expires_at.nil? || expires_at > Time.current)
  end

  def expired?
    status == 'expired' || (expires_at.present? && expires_at <= Time.current)
  end

  def days_remaining
    return nil unless expires_at
    [(expires_at.to_date - Date.current).to_i, 0].max
  end

  def activate!(payment_intent_id: nil, subscription_id: nil)
    update!(
      status: 'active',
      starts_at: Time.current,
      expires_at: calculate_expiry,
      stripe_payment_intent_id: payment_intent_id,
      stripe_subscription_id: subscription_id
    )
  end

  def cancel!
    update!(status: 'canceled')
    
    if stripe_subscription_id.present?
      begin
        Stripe::Subscription.cancel(stripe_subscription_id)
      rescue Stripe::StripeError => e
        Rails.logger.error "Failed to cancel Stripe subscription: #{e.message}"
      end
    end
  end

  private

  def calculate_expiry
    return nil if shop_product.one_time?
    
    case shop_product.interval
    when 'month' then 1.month.from_now
    when 'year' then 1.year.from_now
    else nil
    end
  end
end

