# OmniAuth configuration for Hack Club authentication.
# Only loads if credentials are present.
if ENV["HACKCLUB_CLIENT_ID"].present? && ENV["HACKCLUB_CLIENT_SECRET"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :hack_club,
             ENV["HACKCLUB_CLIENT_ID"],
             ENV["HACKCLUB_CLIENT_SECRET"],
             scope: "openid profile email name slack_id verification_status",
             staging: false
  end

  # Handle OmniAuth failures gracefully
  OmniAuth.config.on_failure = proc do |env|
    OmniAuth::FailureEndpoint.new(env).redirect_to_failure
  end

  # Allow both POST and GET for OAuth
  OmniAuth.config.allowed_request_methods = [:post, :get]
  OmniAuth.config.silence_get_warning = true
  
  # Disable origin check (CSRF) - session cookie handles auth security
  OmniAuth.config.request_validation_phase = nil
else
  Rails.logger.warn("OmniAuth not configured: HACKCLUB_CLIENT_ID or HACKCLUB_CLIENT_SECRET missing")
end
