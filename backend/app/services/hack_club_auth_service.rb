# Verifies Hack Club OAuth tokens and retrieves user info.
# Used in the token-based auth flow where the frontend handles OAuth.
class HackClubAuthService
  HC_API_URL = ENV.fetch("HACK_CLUB_API_URL", "https://hackclub.com/api/v1/users/me")

  # Verifies an access token with Hack Club's API and returns user info.
  # @param access_token [String] the OAuth access token from the frontend
  # @return [Hash, nil] user info hash or nil if verification fails
  def self.verify_token(access_token)
    response = Faraday.get(HC_API_URL) do |req|
      req.headers["Authorization"] = "Bearer #{access_token}"
    end

    return nil unless response.success?

    JSON.parse(response.body).with_indifferent_access
  rescue Faraday::Error, JSON::ParserError
    nil
  end
end
