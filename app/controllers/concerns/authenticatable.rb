# Provides JWT-based authentication methods for controllers.
# Include this concern and use `before_action :authenticate_user!` on protected routes.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  # Authenticates the user via JWT in the Authorization header,
  # or falls back to session-based auth for browser requests.
  # Halts the request with 401 if authentication fails.
  def authenticate_user!
    @current_user = authenticate_via_jwt || authenticate_via_session

    if @current_user.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  private

  # Attempts JWT authentication from Authorization header.
  # @return [User, nil] the authenticated user or nil
  def authenticate_via_jwt
    token = extract_token
    return nil if token.blank?

    payload = JwtService.decode(token)
    return nil if payload.nil?

    User.find_by(id: payload[:user_id])
  end

  # Attempts session-based authentication for browser requests.
  # @return [User, nil] the authenticated user or nil
  def authenticate_via_session
    return nil unless session[:user_id]

    User.find_by(id: session[:user_id])
  end

  # Extracts JWT from Authorization header (Bearer token format).
  # @return [String, nil] the token or nil
  def extract_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end
end
