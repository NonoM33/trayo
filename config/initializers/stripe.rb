# Configuration Stripe
# Les clés doivent être définies via les variables d'environnement (.env):
# - STRIPE_SECRET_KEY
# - STRIPE_PUBLISHABLE_KEY

if ENV['STRIPE_SECRET_KEY'].present?
  Stripe.api_key = ENV['STRIPE_SECRET_KEY']
elsif Rails.env.production?
  raise "STRIPE_SECRET_KEY must be set in production environment"
end

if ENV['STRIPE_PUBLISHABLE_KEY'].present?
  Rails.application.config.stripe_publishable_key = ENV['STRIPE_PUBLISHABLE_KEY']
elsif Rails.env.production?
  raise "STRIPE_PUBLISHABLE_KEY must be set in production environment"
else
  Rails.application.config.stripe_publishable_key = nil
end
