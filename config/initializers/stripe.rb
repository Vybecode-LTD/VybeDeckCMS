# Stripe API initializer — keys are Railway env vars, never committed.
# Set STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET on the Railway service.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
