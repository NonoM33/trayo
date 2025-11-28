Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', '***REMOVED***')

Rails.application.config.stripe_publishable_key = ENV.fetch('STRIPE_PUBLISHABLE_KEY', '***REMOVED***')

