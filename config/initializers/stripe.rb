if Rails.env.development? && Rails.root.join(".env").file?
	require "dotenv/load"
end

Stripe.api_key = ENV["STRIPE_SECRET_KEY"].presence ||
								 Rails.application.credentials.dig(:stripe, :secret_key)