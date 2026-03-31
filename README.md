![License](https://img.shields.io/badge/license-MIT-blue.svg)

# Rails + Mainlayer SaaS Starter

A production-ready SaaS template built with Ruby on Rails 7 and integrated with Mainlayer for subscription billing and payment infrastructure.

## Features

- **Rails 7** with Devise for authentication
- **Mainlayer Integration** for subscription management
- **Three-tier Plans** (Free, Pro, Enterprise)
- **Feature Flags** on User model (pro?, enterprise?, can_use_sso?)
- **Plan Enforcement** middleware with `require_plan!` helper
- **Billing Routes** for plan management and cancellation
- **Type-safe API** with proper error handling
- **Test Suite** with Minitest and WebMock

## Quick Start

### 1. Clone and Install

```bash
git clone <repo-url> my-saas
cd my-saas
bundle install
```

### 2. Environment Setup

```bash
cp .env.example .env.local
```

Configure these environment variables:

```env
# Mainlayer API
MAINLAYER_API_KEY="your-api-key-from-dashboard.mainlayer.fr"
MAINLAYER_API_URL="https://api.mainlayer.fr"

# Resource IDs (from https://dashboard.mainlayer.fr/resources)
MAINLAYER_RESOURCE_FREE="res_free_xxx"
MAINLAYER_RESOURCE_PRO="res_pro_xxx"
MAINLAYER_RESOURCE_ENTERPRISE="res_enterprise_xxx"

# Database
DATABASE_URL="postgresql://user:password@localhost/mainlayer_saas_dev"

# Rails
RAILS_MASTER_KEY="generate with: rails credentials:edit"
```

### 3. Database Setup

```bash
bundle exec rails db:setup
```

### 4. Run Development Server

```bash
bundle exec rails server
```

Open [http://localhost:3000](http://localhost:3000)

## Project Structure

```
app/
  ├── controllers/
  │   ├── application_controller.rb   # Plan enforcement helpers
  │   ├── billing_controller.rb       # Subscription management
  │   └── dashboard_controller.rb     # Protected routes
  ├── models/
  │   └── user.rb                     # Plan helpers and feature flags
  ├── services/
  │   └── mainlayer_service.rb        # Mainlayer API client
  └── views/
      ├── billing/                    # Plan cards and checkout
      └── dashboard/                  # User dashboard
```

## Key Files

### Mainlayer Service (`app/services/mainlayer_service.rb`)

Type-safe API client for managing subscriptions:

```ruby
# Get available plans
MainlayerService.plans
# => { free: {...}, pro: {...}, enterprise: {...} }

# Check subscription status
MainlayerService.check_subscription(user_id: '123', plan: :pro)
# => { active: true, subscription_id: 'sub_123', ... }

# Create subscription
MainlayerService.create_subscription(user_id: '123', plan: :pro)

# Cancel subscription
MainlayerService.cancel_subscription(subscription_id: 'sub_123')
```

### User Model (`app/models/user.rb`)

Plan helpers and feature flags:

```ruby
user = User.find(123)

# Plan checks
user.free?          # => true
user.pro?           # => false
user.enterprise?    # => false

# Feature flags
user.can_use_advanced_analytics?   # => false
user.can_use_custom_webhooks?      # => true
user.can_use_sso?                  # => false
user.api_rate_limit                # => 100

# Subscription management
user.create_subscription(:pro)
user.get_subscription(:pro)
user.cancel_subscription('sub_id')
```

### ApplicationController (`app/controllers/application_controller.rb`)

Plan enforcement middleware:

```ruby
class AnalyticsController < ApplicationController
  before_action :require_plan!, only: [:advanced]
  before_action -> { require_plan!(:pro) }, only: [:custom_webhooks]
  before_action -> { require_plan!(:enterprise) }, only: [:sso_settings]
end
```

## Usage Examples

### Protect Routes Based on Plan

```ruby
# Require any paid plan
class ProFeaturesController < ApplicationController
  before_action :require_plan!, only: [:advanced_analytics]
end

# Require specific plan
class AnalyticsController < ApplicationController
  before_action -> { require_plan!(:pro) }, only: [:custom_metrics]
  before_action -> { require_plan!(:enterprise) }, only: [:dedicated_support]
end
```

### Display Conditional Features

```erb
<% if current_user.pro? %>
  <div class="advanced-analytics">
    <%= render 'advanced_analytics' %>
  </div>
<% else %>
  <p><%= link_to 'Upgrade to Pro', billing_path %></p>
<% end %>
```

### Check Subscription Status

```ruby
subscription = current_user.get_subscription(:pro)
if subscription
  puts "Current period ends: #{subscription['current_period_end']}"
  puts "Status: #{subscription['status']}"
end
```

## Plan Configuration

Plans are defined in `app/services/mainlayer_service.rb`:

```ruby
PLANS = {
  free: {
    name: 'Free',
    price_usd_cents: 0,
    features: ['Up to 100 API calls/month', ...],
    resource_id: ENV['MAINLAYER_RESOURCE_FREE'],
  },
  pro: {
    name: 'Pro',
    price_usd_cents: 2900,
    features: ['Up to 50,000 API calls/month', ...],
    resource_id: ENV['MAINLAYER_RESOURCE_PRO'],
  },
  enterprise: {
    name: 'Enterprise',
    price_usd_cents: 9900,
    features: ['Unlimited API calls', ...],
    resource_id: ENV['MAINLAYER_RESOURCE_ENTERPRISE'],
  },
}
```

Update `MAINLAYER_RESOURCE_*` environment variables with your actual Mainlayer resource IDs.

## API Reference

### MainlayerService

#### `plans`
Returns hash of all plan configurations.

#### `get_plan(plan)`
Get a specific plan by ID.

```ruby
MainlayerService.get_plan(:pro)
# => { name: 'Pro', price_usd_cents: 2900, ... }
```

#### `create_subscription(user_id:, plan:)`
Create a subscription for a user.

```ruby
subscription = MainlayerService.create_subscription(
  user_id: '123',
  plan: :pro
)
```

#### `check_subscription(user_id:, plan:)`
Check if user has active subscription.

```ruby
status = MainlayerService.check_subscription(
  user_id: '123',
  plan: :pro
)
# => { active: true, subscription_id: '...', ... }
```

#### `current_plan(user_id:)`
Get highest tier plan user has access to.

```ruby
MainlayerService.current_plan(user_id: '123')
# => :enterprise
```

#### `cancel_subscription(subscription_id:)`
Cancel an existing subscription.

```ruby
MainlayerService.cancel_subscription(subscription_id: 'sub_123')
```

## Testing

```bash
# Run all tests
bundle exec rails test

# Run specific test file
bundle exec rails test test/services/mainlayer_service_test.rb

# Run tests with coverage
COVERAGE=true bundle exec rails test
```

## Deployment

### Environment Variables

Set these on your hosting platform (Heroku, Render, etc.):

```
MAINLAYER_API_KEY
MAINLAYER_API_URL
MAINLAYER_RESOURCE_FREE
MAINLAYER_RESOURCE_PRO
MAINLAYER_RESOURCE_ENTERPRISE
RAILS_MASTER_KEY
DATABASE_URL
```

### Database

```bash
bundle exec rails db:migrate RAILS_ENV=production
```

### Build

```bash
bundle install --deployment
bundle exec rake assets:precompile
```

## Security Considerations

- **API Keys**: Never commit `.env.local` — use `.env.example` as template
- **User IDs**: Always use authenticated user's ID from session
- **Plan Checks**: Validate subscription server-side, not client-side
- **HTTPS**: Always use HTTPS in production for API calls
- **Rate Limiting**: Implement rate limiting based on plan tiers

## Troubleshooting

### "MAINLAYER_API_KEY environment variable is required"

Ensure `MAINLAYER_API_KEY` is set in `.env.local`. Get it from [https://dashboard.mainlayer.fr/settings/api-keys](https://dashboard.mainlayer.fr/settings/api-keys)

### Resource IDs not found

Verify that `MAINLAYER_RESOURCE_*` environment variables match your actual resource IDs in the Mainlayer dashboard.

### "Mainlayer API error 401"

Your API key may be invalid or expired. Check [https://dashboard.mainlayer.fr/settings/api-keys](https://dashboard.mainlayer.fr/settings/api-keys)

## Support

- **Mainlayer Docs**: https://docs.mainlayer.fr
- **Rails Docs**: https://guides.rubyonrails.org
- **Devise Docs**: https://github.com/heartcombo/devise
- **Mainlayer Support**: https://support.mainlayer.fr

## License

MIT
