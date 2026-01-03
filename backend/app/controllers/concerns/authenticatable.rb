# Provides JWT-based authentication methods for controllers.
# Include this concern and use `before_action :authenticate_user!` on protected routes.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  # Authenticates the user via JWT in the Authorization header.
  # Halts the request with 401 if authentication fails.
  def authenticate_user!
    token = extract_token
    payload = JwtService.decode(token)

    if payload.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    @current_user = User.find_by(id: payload[:user_id])

    if @current_user.nil?
      render json: { error: "User not found" }, status: :unauthorized
    end
  end

  private

  # Extracts JWT from Authorization header (Bearer token format).
  def extract_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end
end
