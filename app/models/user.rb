# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Return the user's current Mainlayer plan.
  # This performs a live check against the Mainlayer API.
  # For performance, cache this in your session or Redis layer.
  def mainlayer_plan
    MainlayerService.current_plan(user_id: id.to_s)
  end

  def pro?
    %i[pro enterprise].include?(mainlayer_plan)
  end

  def enterprise?
    mainlayer_plan == :enterprise
  end

  # Feature flag helpers — add your own as needed
  def can_use_advanced_analytics?
    pro? || enterprise?
  end

  def can_use_sso?
    enterprise?
  end
end
