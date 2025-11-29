# Configuration Stripe
# En production, les clés doivent être définies via les variables d'environnement:
# - STRIPE_SECRET_KEY (sk_live_...)
# - STRIPE_PUBLISHABLE_KEY (pk_live_...)

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY') do
  if Rails.env.production?
    raise "STRIPE_SECRET_KEY must be set in production environment"
  else
    # Clés de test uniquement pour le développement
    '***REMOVED***'
  end
end

Rails.application.config.stripe_publishable_key = ENV.fetch('STRIPE_PUBLISHABLE_KEY') do
  if Rails.env.production?
    raise "STRIPE_PUBLISHABLE_KEY must be set in production environment"
  else
    # Clés de test uniquement pour le développement
    '***REMOVED***'
  end
end
