class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Authenticatable
  include Authorizable

  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  protected

  SHIPPING_DEADLINE = Time.utc(2026, 2, 26, 4, 59, 59)

  def check_shipping_deadline
    if Time.now.utc > SHIPPING_DEADLINE
      render json: { error: "The deadline for shipping and journal entries has passed." }, status: :forbidden
    end
  end
end
