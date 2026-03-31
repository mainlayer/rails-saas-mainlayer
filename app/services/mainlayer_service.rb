# app/services/mainlayer_service.rb
#
# Service for managing Mainlayer subscriptions and billing.
# Provides methods for checking subscription status, creating subscriptions,
# and managing user plans.
class MainlayerService
  class Error < StandardError; end

  API_URL = ENV.fetch('MAINLAYER_API_URL', 'https://api.mainlayer.fr')
  API_KEY = ENV.fetch('MAINLAYER_API_KEY')

  # Plan configurations with pricing and features
  PLANS = {
    free: {
      name: 'Free',
      description: 'Perfect for getting started',
      price_usd_cents: 0,
      interval: 'month',
      features: [
        'Up to 100 API calls per month',
        'Basic analytics',
        'Email support',
      ],
      resource_id: ENV.fetch('MAINLAYER_RESOURCE_FREE', 'res_free'),
    },
    pro: {
      name: 'Pro',
      description: 'For growing applications',
      price_usd_cents: 2900,
      interval: 'month',
      features: [
        'Up to 50,000 API calls per month',
        'Advanced analytics',
        'Priority support',
        'Custom webhooks',
      ],
      resource_id: ENV.fetch('MAINLAYER_RESOURCE_PRO', 'res_pro'),
    },
    enterprise: {
      name: 'Enterprise',
      description: 'Unlimited scale with dedicated support',
      price_usd_cents: 9900,
      interval: 'month',
      features: [
        'Unlimited API calls',
        'Dedicated account manager',
        'Custom integrations',
        'SLA guarantee',
      ],
      resource_id: ENV.fetch('MAINLAYER_RESOURCE_ENTERPRISE', 'res_enterprise'),
    },
  }.freeze

  # List all available plans
  #
  # @return [Hash] Plans keyed by symbol
  def self.plans
    PLANS
  end

  # Get a specific plan by ID
  #
  # @param plan [String, Symbol] Plan ID
  # @return [Hash, nil] Plan configuration or nil
  def self.get_plan(plan)
    PLANS[plan.to_sym]
  end

  # Create a subscription for a user and plan
  #
  # @param user_id [String] User ID
  # @param plan [String, Symbol] Plan ID (:free, :pro, :enterprise)
  # @return [Hash] Subscription response
  # @raises [Error] If API call fails
  def self.create_subscription(user_id:, plan:)
    plan_config = get_plan(plan)
    raise Error, "Unknown plan: #{plan}" unless plan_config

    response = api_request(
      :post,
      '/subscriptions/approve',
      resource_id: plan_config[:resource_id],
      user_id: user_id
    )

    response
  end

  # Get subscription status for a user and plan
  #
  # @param user_id [String] User ID
  # @param resource_id [String] Mainlayer resource ID
  # @return [Hash, nil] Subscription details or nil if not found
  def self.get_subscription(user_id:, resource_id:)
    api_request(
      :get,
      '/subscriptions/status',
      query: { resource_id: resource_id, user_id: user_id }
    )
  rescue Error => e
    if e.message.include?('404')
      return nil
    end
    Rails.logger.error "[Mainlayer] get_subscription error: #{e.message}"
    nil
  end

  # Check if user has an active subscription
  #
  # @param user_id [String] User ID
  # @param plan [String, Symbol] Plan ID
  # @return [Hash] { active: Boolean, subscription_id: String|nil, ... }
  def self.check_subscription(user_id:, plan:)
    plan_config = get_plan(plan)
    return { active: false } unless plan_config

    subscription = get_subscription(user_id: user_id, resource_id: plan_config[:resource_id])

    {
      active: subscription&.dig('status') == 'active',
      subscription_id: subscription&.dig('subscription_id'),
      resource_id: subscription&.dig('resource_id'),
      status: subscription&.dig('status'),
      current_period_end: subscription&.dig('current_period_end'),
    }
  end

  # Determine the highest tier plan a user is authorized for
  #
  # @param user_id [String] User ID
  # @return [Symbol] :enterprise, :pro, or :free
  def self.current_plan(user_id:)
    if check_subscription(user_id: user_id, plan: :enterprise)[:active]
      :enterprise
    elsif check_subscription(user_id: user_id, plan: :pro)[:active]
      :pro
    else
      :free
    end
  end

  # Cancel a subscription
  #
  # @param subscription_id [String] Subscription ID
  # @return [Hash] Updated subscription response
  # @raises [Error] If API call fails
  def self.cancel_subscription(subscription_id:)
    api_request(
      :post,
      '/subscriptions/cancel',
      subscription_id: subscription_id
    )
  end

  # Make an HTTP request to the Mainlayer API
  #
  # @param method [Symbol] HTTP method (:get, :post, etc.)
  # @param endpoint [String] API endpoint path
  # @param body [Hash] Request body (for POST/PATCH)
  # @param query [Hash] Query parameters (for GET)
  # @return [Hash] Parsed JSON response
  # @raises [Error] If request fails
  private

  def self.api_request(method, endpoint, body: {}, query: {})
    url = URI.join(API_URL, endpoint)
    url.query = URI.encode_www_form(query) if query.any?

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'

    request_class = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      patch: Net::HTTP::Patch,
      delete: Net::HTTP::Delete,
    }.fetch(method.to_sym, Net::HTTP::Get)

    request = request_class.new(url)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{API_KEY}"

    request.body = JSON.generate(body) if body.any?

    response = http.request(request)

    if response.code.to_i >= 400
      raise Error, "Mainlayer API error #{response.code}: #{response.body}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise Error, "Invalid JSON response from Mainlayer API: #{e.message}"
  rescue StandardError => e
    raise Error, "Mainlayer API request failed: #{e.message}"
  end
end
