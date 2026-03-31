#!/usr/bin/env ruby
# examples/basic_integration.rb
#
# Standalone example showing how to use Mainlayer for subscription checks.
# Run with: MAINLAYER_API_KEY=your_key ruby examples/basic_integration.rb

require "mainlayer"

Mainlayer.configure do |config|
  config.api_key = ENV.fetch("MAINLAYER_API_KEY")
  config.base_url = ENV.fetch("MAINLAYER_BASE_URL", "https://api.mainlayer.fr")
end

PRO_RESOURCE_ID = ENV.fetch("MAINLAYER_PRO_RESOURCE_ID", "plan_pro")
USER_ID = "user_demo_123"

puts "=== Mainlayer Basic Integration Example ==="

# 1. Check subscription status
puts "\n1. Checking subscription status..."
response = Mainlayer::Resources.verify_access(PRO_RESOURCE_ID, USER_ID)
puts "   Authorized: #{response.authorized}"
puts "   Plan: #{response.metadata&.dig('plan') || 'free'}"

if response.authorized
  puts "\n2. User has Pro access — creating billing portal session..."
  portal = Mainlayer::Billing.create_portal_session(
    user_id:    USER_ID,
    return_url: "https://yourapp.com/billing",
  )
  puts "   Portal URL: #{portal.url}"
else
  puts "\n2. User does not have Pro — creating checkout session..."
  session = Mainlayer::Checkout.create(
    resource_id:  PRO_RESOURCE_ID,
    user_id:      USER_ID,
    success_url:  "https://yourapp.com/billing?success=true",
    cancel_url:   "https://yourapp.com/billing?canceled=true",
  )
  puts "   Checkout URL: #{session.url}"
end

puts "\nDone."
