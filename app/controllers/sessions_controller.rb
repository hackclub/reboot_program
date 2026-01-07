# Handles OmniAuth callbacks for Hack Club authentication.
class SessionsController < ActionController::Base
  protect_from_forgery with: :exception, except: [ :create, :failure ]

  # GET /auth/hackclub/callback
  # OmniAuth success callback - creates/updates user and logs them in.
  def create
    auth = request.env["omniauth.auth"]

    if auth.nil?
      redirect_to root_path, flash: { error: "Authentication failed" }
      return
    end

    user = find_or_create_user(auth)
    store_hca_token(user, auth)

    session[:user_id] = user.id
    session[:jwt] = JwtService.encode(user_id: user.id)

    redirect_to projects_path, flash: { success: "Welcome back!" }
  end

  # GET /auth/failure
  # OmniAuth failure callback.
  def failure
    redirect_to root_path, flash: { error: "Authentication failed: #{params[:message]}" }
  end

  private

  # Finds or creates a user from OmniAuth data.
  def find_or_create_user(auth)
    user = User.find_or_initialize_by(provider: "hack_club", uid: auth.uid.to_s)
    user.email = auth.info.email
    user.slack_id = auth.info.slack_id || auth.extra&.raw_info&.slack_id
    user.slack_username = auth.info.nickname || auth.info.name
    user.first_name = auth.info.first_name || auth.extra&.raw_info&.first_name
    user.last_name = auth.info.last_name || auth.extra&.raw_info&.last_name
    user.birthday = parse_birthday(auth.extra&.raw_info&.dig("identity", "birthday"))
    user.save!
    user
  end

  # Parses birthday from various formats.
  def parse_birthday(value)
    return nil if value.blank?
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  # Stores the HCA access token for later use (YSWS submissions).
  def store_hca_token(user, auth)
    user.update!(
      hca_token: auth.credentials.token,
      hca_token_expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : 30.days.from_now
    )
  end
end
