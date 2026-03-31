# config/initializers/mainlayer.rb
#
# Configure the Mainlayer client for your Rails app.
# Set MAINLAYER_API_KEY in your environment (e.g. .env or Rails credentials).

raise "MAINLAYER_API_KEY is not set" if ENV["MAINLAYER_API_KEY"].blank?

Mainlayer.configure do |config|
  config.api_key = ENV["MAINLAYER_API_KEY"]
  config.base_url = ENV.fetch("MAINLAYER_BASE_URL", "https://api.mainlayer.fr")
end

# Plan resource IDs — configure these in your Mainlayer dashboard
MAINLAYER_PLAN_RESOURCE_IDS = {
  free:       ENV.fetch("MAINLAYER_FREE_RESOURCE_ID", "plan_free"),
  pro:        ENV.fetch("MAINLAYER_PRO_RESOURCE_ID", "plan_pro"),
  enterprise: ENV.fetch("MAINLAYER_ENTERPRISE_RESOURCE_ID", "plan_enterprise"),
}.freeze
