# app/services/mainlayer_service.rb
#
# Thin wrapper around the Mainlayer SDK for subscription and billing operations.
class MainlayerService
  class Error < StandardError; end

  # Verify whether a user has access to a given resource/plan.
  #
  # @param user_id [String] The ID of the user to check
  # @param resource_id [String] The Mainlayer resource ID (e.g. "plan_pro")
  # @return [Hash] { authorized: Boolean, plan: String, expires_at: String|nil }
  def self.check_subscription(user_id:, resource_id:)
    response = Mainlayer::Resources.verify_access(resource_id, user_id)
    {
      authorized: response.authorized,
      plan:       response.metadata&.dig("plan") || "free",
      expires_at: response.metadata&.dig("expiresAt"),
    }
  rescue Mainlayer::Error => e
    Rails.logger.error "[Mainlayer] check_subscription error: #{e.message}"
    { authorized: false, plan: "free", expires_at: nil }
  end

  # Determine the highest plan a user is authorized for.
  #
  # @param user_id [String]
  # @return [Symbol] :enterprise, :pro, or :free
  def self.current_plan(user_id:)
    if check_subscription(user_id: user_id, resource_id: MAINLAYER_PLAN_RESOURCE_IDS[:enterprise])[:authorized]
      :enterprise
    elsif check_subscription(user_id: user_id, resource_id: MAINLAYER_PLAN_RESOURCE_IDS[:pro])[:authorized]
      :pro
    else
      :free
    end
  end

  # Create a Mainlayer checkout session for plan upgrade.
  #
  # @param user_id [String]
  # @param plan [Symbol] :pro or :enterprise
  # @param success_url [String]
  # @param cancel_url [String]
  # @return [String] URL to redirect the user to
  def self.create_checkout_session(user_id:, plan:, success_url:, cancel_url:)
    resource_id = MAINLAYER_PLAN_RESOURCE_IDS.fetch(plan.to_sym) do
      raise Error, "Unknown plan: #{plan}"
    end
    session = Mainlayer::Checkout.create(
      resource_id:  resource_id,
      user_id:      user_id,
      success_url:  success_url,
      cancel_url:   cancel_url,
    )
    session.url
  end

  # Open a billing portal session for managing an existing subscription.
  #
  # @param user_id [String]
  # @param return_url [String]
  # @return [String] URL to redirect the user to
  def self.create_billing_portal_session(user_id:, return_url:)
    portal = Mainlayer::Billing.create_portal_session(
      user_id:    user_id,
      return_url: return_url,
    )
    portal.url
  end
end
