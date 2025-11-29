# Configuration Stripe
# Les clés doivent être définies via les variables d'environnement:
# - STRIPE_SECRET_KEY
# - STRIPE_PUBLISHABLE_KEY

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY') do
  if Rails.env.production?
    raise "STRIPE_SECRET_KEY must be set in production environment"
  else
    nil
  end
end

Rails.application.config.stripe_publishable_key = ENV.fetch('STRIPE_PUBLISHABLE_KEY') do
  if Rails.env.production?
    raise "STRIPE_PUBLISHABLE_KEY must be set in production environment"
  else
    nil
  end
end
