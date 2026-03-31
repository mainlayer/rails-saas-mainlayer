# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  # Verify the current user has at least the given plan.
  # Usage in a controller: before_action -> { require_plan!(:pro) }
  def require_plan!(minimum_plan)
    plan_hierarchy = { free: 0, pro: 1, enterprise: 2 }
    user_plan = MainlayerService.current_plan(user_id: current_user.id.to_s)

    unless plan_hierarchy.fetch(user_plan, 0) >= plan_hierarchy.fetch(minimum_plan.to_sym, 0)
      respond_to do |format|
        format.html { redirect_to billing_path, alert: "Please upgrade your plan to access this feature." }
        format.json { render json: { error: "Forbidden: requires #{minimum_plan} plan." }, status: :forbidden }
      end
    end
  end

  # Expose current plan to views
  def current_plan
    @current_plan ||= MainlayerService.current_plan(user_id: current_user.id.to_s)
  end
  helper_method :current_plan

  private

  # Helper to DRY plan gating in subcontrollers
  def mainlayer_check(plan)
    before_action -> { require_plan!(plan) }
  end
end
