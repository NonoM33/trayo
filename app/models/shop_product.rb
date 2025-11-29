class ShopProduct < ApplicationRecord
  PRODUCT_TYPES = %w[subscription one_time].freeze
  INTERVALS = %w[month year one_time].freeze

  has_many :product_purchases, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_type, presence: true, inclusion: { in: PRODUCT_TYPES }
  validates :interval, inclusion: { in: INTERVALS }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }
  scope :subscriptions, -> { where(product_type: 'subscription') }
  scope :one_time, -> { where(product_type: 'one_time') }

  def features_list
    return [] if features.blank?
    features.split("\n").map(&:strip).reject(&:blank?)
  end

  def subscription?
    product_type == 'subscription'
  end

  def one_time?
    product_type == 'one_time'
  end

  def formatted_price
    if subscription?
      "#{price.to_i}€/#{interval == 'month' ? 'mois' : 'an'}"
    else
      "#{price.to_i}€"
    end
  end

  def interval_label
    case interval
    when 'month' then 'par mois'
    when 'year' then 'par an'
    else ''
    end
  end

  def create_stripe_product!
    return if stripe_product_id.present?

    product = Stripe::Product.create(
      name: name,
      description: description,
      metadata: { shop_product_id: id }
    )

    price_params = {
      product: product.id,
      unit_amount: (price * 100).to_i,
      currency: 'eur'
    }

    if subscription?
      price_params[:recurring] = { interval: interval }
    end

    stripe_price = Stripe::Price.create(price_params)

    update!(
      stripe_product_id: product.id,
      stripe_price_id: stripe_price.id
    )
  end

  def self.seed_maintenance_pack!
    find_or_create_by!(name: "Pack Maintenance Annuelle") do |product|
      product.description = "Gardez vos bots à jour et performants toute l'année"
      product.product_type = 'subscription'
      product.price = 99.00
      product.interval = 'year'
      product.icon = 'fa-wrench'
      product.badge = 'POPULAIRE'
      product.badge_color = 'emerald'
      product.position = 1
      product.features = <<~FEATURES
        Mises à jour automatiques des bots
        Support prioritaire 7j/7
        Nouveaux paramètres optimisés
        Accès anticipé aux nouvelles fonctionnalités
        Optimisation continue des performances
      FEATURES
    end
  end
end

