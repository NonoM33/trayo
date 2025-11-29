# Configuration Stripe
# Les clés doivent être définies via les variables d'environnement:
# - STRIPE_SECRET_KEY
# - STRIPE_PUBLISHABLE_KEY

STRIPE_TEST_SECRET_KEY = "sk_test_REMOVED".freeze
STRIPE_TEST_PUBLISHABLE_KEY = "pk_test_REMOVED".freeze

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY') do
  if Rails.env.production?
    raise "STRIPE_SECRET_KEY must be set in production environment"
  else
    STRIPE_TEST_SECRET_KEY
  end
end

Rails.application.config.stripe_publishable_key = ENV.fetch('STRIPE_PUBLISHABLE_KEY') do
  if Rails.env.production?
    raise "STRIPE_PUBLISHABLE_KEY must be set in production environment"
  else
    STRIPE_TEST_PUBLISHABLE_KEY
  end
end
