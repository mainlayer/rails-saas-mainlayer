![CI](https://github.com/your-org/rails-saas-mainlayer/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

# rails-saas-mainlayer

Ruby on Rails 7 SaaS template with Mainlayer subscription billing — Devise auth, plan-based feature flags, and billing portal built in.

## Installation

```bash
git clone https://github.com/your-org/rails-saas-mainlayer.git
cd rails-saas-mainlayer
bundle install
```

## Quickstart

```bash
cp .env.example .env          # Add MAINLAYER_API_KEY
bundle exec rails db:setup
bundle exec rails server      # http://localhost:3000
```

Set the following environment variables:

| Variable | Description |
|---|---|
| `MAINLAYER_API_KEY` | Your Mainlayer secret key |
| `MAINLAYER_PRO_RESOURCE_ID` | Resource ID for Pro plan |
| `MAINLAYER_ENTERPRISE_RESOURCE_ID` | Resource ID for Enterprise plan |

## Features

- Rails 7 with Devise authentication
- `MainlayerService` for subscription checks and checkout
- `require_plan!` before_action helper on `ApplicationController`
- Plan-based feature flags on the `User` model (`pro?`, `enterprise?`, `can_use_sso?`)
- Billing portal controller with subscribe + portal actions
- Minitest suite with WebMock

## Running Tests

```bash
bundle install && bundle exec rails test
```

📚 Docs at [mainlayer.fr](https://mainlayer.fr)
