# Handles token-based authentication for the API.
# Frontend performs OAuth with Hack Club, then sends the access token here.
class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user!, only: [ :me ]

  # POST /api/v1/auth/token
  # Exchanges a Hack Club OAuth token for a JWT.
  #
  # @param access_token [String] OAuth access token from Hack Club
  # @return [JSON] { token: jwt, user: user_data } or { error: message }
  def token
    access_token = params[:access_token]

    if access_token.blank?
      return render json: { error: "Access token is required" }, status: :bad_request
    end

    hc_user = HackClubAuthService.verify_token(access_token)

    if hc_user.nil?
      return render json: { error: "Invalid or expired access token" }, status: :unauthorized
    end

    user = find_or_create_user(hc_user, access_token)
    jwt = JwtService.encode(user_id: user.id)

    render json: { token: jwt, user: user_response(user) }
  end

  # GET /api/v1/auth/me
  # Returns the current authenticated user.
  def me
    render json: { user: user_response(current_user) }
  end

  private

  # Finds existing user or creates new one from Hack Club user data.
  # Also stores the HCA token for later use (e.g., YSWS PII autofill).
  def find_or_create_user(hc_user, access_token)
    user = User.find_or_initialize_by(provider: "hack_club", uid: hc_user[:id].to_s)
    user.email = hc_user[:email]
    user.slack_id = hc_user[:slack_id]
    user.slack_username = hc_user[:slack_username] || hc_user[:username]
    user.hca_token = access_token
    user.hca_token_expires_at = 30.days.from_now
    user.save!
    user
  end

  # Formats user data for API response.
  def user_response(user)
    {
      id: user.id,
      email: user.email,
      slack_username: user.slack_username
    }
  end
end
