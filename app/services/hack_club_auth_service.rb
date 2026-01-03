require "faraday"
require "json"

# Service for interacting with Hack Club Auth (HCA) API.
# Handles token verification and user identity fetching.
module HackClubAuthService
  class Error < StandardError; end

  module_function

  # Returns the HCA host URL based on environment.
  # @return [String] the HCA host URL
  def host
      "https://auth.hackclub.com"
  end

  # Builds backend URL for HCA.
  # @param path [String] optional path to append
  # @return [String] the full backend URL
  def backend_url(path = "")
    "#{host}/backend#{path}"
  end

  # Fetches the current user's info from HCA.
  # @param access_token [String] the OAuth access token
  # @return [Hash, nil] user info or nil if fetch fails
  def me(access_token)
    raise ArgumentError, "access_token is required" if access_token.blank?

    response = connection.get("/api/v1/me") do |req|
      req.headers["Authorization"] = "Bearer #{access_token}"
      req.headers["Accept"] = "application/json"
    end

    unless response.success?
      Rails.logger.warn("HCA /me fetch failed with status #{response.status}")
      return nil
    end

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.warn("HCA /me fetch error: #{e.class}: #{e.message}")
    nil
  end

  # Fetches just the identity portion of user info.
  # @param access_token [String] the OAuth access token
  # @return [Hash] identity hash or empty hash if fetch fails
  def identity(access_token)
    result = me(access_token)
    result&.dig("identity") || {}
  end

  # Verifies an access token and returns user info.
  # Alias for me() for backwards compatibility.
  # @param access_token [String] the OAuth access token
  # @return [Hash, nil] user info or nil if invalid
  def verify_token(access_token)
    me(access_token)
  end

  # Builds a portal URL for user actions.
  # @param path [String] the portal path
  # @param return_to [String] URL to return to after action
  # @return [String] the full portal URL
  def portal_url(path, return_to:)
    uri = URI.join(host, "/portal/#{path}")
    uri.query = { return_to: return_to }.to_query
    uri.to_s
  end

  # Builds URL for address collection portal.
  # @param return_to [String] URL to return to after collecting address
  # @return [String] the address portal URL
  def address_portal_url(return_to:)
    portal_url("address", return_to:)
  end

  # Builds URL for identity verification portal.
  # @param return_to [String] URL to return to after verification
  # @return [String] the verify portal URL
  def verify_portal_url(return_to:)
    portal_url("verify", return_to:)
  end

  # Faraday connection instance for HCA API.
  # @return [Faraday::Connection] the connection
  def connection
    @connection ||= Faraday.new(url: host)
  end
end
