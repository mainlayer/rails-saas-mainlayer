# app/controllers/billing_controller.rb
class BillingController < ApplicationController
  # No plan check needed — anyone can view billing
  skip_before_action :authenticate_user!, only: []

  # GET /billing
  def index
    @current_plan = MainlayerService.current_plan(user_id: current_user.id.to_s)
    @plans = [
      {
        id: :free,
        name: "Free",
        price: "$0/month",
        description: "Get started for free.",
        features: ["5 projects", "1 GB storage", "Community support"],
      },
      {
        id: :pro,
        name: "Pro",
        price: "$29/month",
        description: "Everything you need to scale.",
        features: ["Unlimited projects", "50 GB storage", "Priority support", "Analytics"],
      },
      {
        id: :enterprise,
        name: "Enterprise",
        price: "Custom",
        description: "For large teams.",
        features: ["Everything in Pro", "SSO", "Audit logs", "SLA"],
      },
    ]
  end

  # POST /billing/subscribe
  def subscribe
    plan = params.require(:plan).to_sym
    unless %i[pro enterprise].include?(plan)
      return redirect_to billing_path, alert: "Invalid plan."
    end

    checkout_url = MainlayerService.create_checkout_session(
      user_id:     current_user.id.to_s,
      plan:        plan,
      success_url: billing_url(success: true),
      cancel_url:  billing_url(canceled: true),
    )
    redirect_to checkout_url, allow_other_host: true
  rescue MainlayerService::Error => e
    redirect_to billing_path, alert: "Could not start checkout: #{e.message}"
  end

  # POST /billing/portal
  def portal
    portal_url = MainlayerService.create_billing_portal_session(
      user_id:    current_user.id.to_s,
      return_url: billing_url,
    )
    redirect_to portal_url, allow_other_host: true
  end
end
