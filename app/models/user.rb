# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Return the user's current Mainlayer plan.
  # Performs a live check against the Mainlayer API.
  # For performance, cache this in session or Redis.
  #
  # @return [Symbol] :enterprise, :pro, or :free
  def mainlayer_plan
    MainlayerService.current_plan(user_id: id.to_s)
  end

  # Check if user has a specific subscription
  #
  # @param plan [Symbol, String] Plan to check
  # @return [Boolean]
  def has_subscription?(plan)
    MainlayerService.check_subscription(user_id: id.to_s, plan: plan)[:active]
  end

  # Plan tier helpers
  def free?
    mainlayer_plan == :free
  end

  def pro?
    %i[pro enterprise].include?(mainlayer_plan)
  end

  def enterprise?
    mainlayer_plan == :enterprise
  end

  # Feature flag helpers — customize based on your plan tiers
  def can_use_advanced_analytics?
    pro? || enterprise?
  end

  def can_use_custom_webhooks?
    pro? || enterprise?
  end

  def can_use_sso?
    enterprise?
  end

  def can_use_api_keys?
    pro? || enterprise?
  end

  def api_rate_limit
    case mainlayer_plan
    when :free
      100
    when :pro
      50_000
    when :enterprise
      Float::INFINITY
    else
      0
    end
  end

  # Create or upgrade subscription
  #
  # @param plan [Symbol, String] Plan to subscribe to
  # @return [Hash] Subscription response
  # @raises [MainlayerService::Error]
  def create_subscription(plan)
    MainlayerService.create_subscription(user_id: id.to_s, plan: plan)
  end

  # Get subscription details
  #
  # @param plan [Symbol, String] Plan
  # @return [Hash, nil]
  def get_subscription(plan)
    plan_config = MainlayerService.get_plan(plan)
    return nil unless plan_config

    MainlayerService.get_subscription(
      user_id: id.to_s,
      resource_id: plan_config[:resource_id]
    )
  end

  # Cancel a subscription
  #
  # @param subscription_id [String]
  # @return [Hash] Updated subscription response
  def cancel_subscription(subscription_id)
    MainlayerService.cancel_subscription(subscription_id: subscription_id)
  end
end
