class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Authenticatable
  include Authorizable

  protect_from_forgery with: :exception, unless: -> { request.format.json? }
end
