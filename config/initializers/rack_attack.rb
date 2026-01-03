# Rate limiting configuration using Rack::Attack.
# Protects against brute force and abuse.
class Rack::Attack
  # Throttle all requests by IP (100 requests per minute)
  throttle("req/ip", limit: 100, period: 1.minute) do |req|
    req.ip
  end

  # Throttle auth attempts by IP (5 per minute)
  throttle("auth/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/token" && req.post?
  end

  # Throttle YSWS submissions by user (10 per hour)
  throttle("ysws/user", limit: 10, period: 1.hour) do |req|
    if req.path == "/api/v1/ysws/submit" && req.post?
      # Extract user from JWT if present
      token = req.get_header("HTTP_AUTHORIZATION")&.split(" ")&.last
      payload = JwtService.decode(token) if token
      payload[:user_id] if payload
    end
  end

  # Block suspicious requests
  blocklist("block/bad-requests") do |req|
    # Block requests with suspicious patterns
    req.path.include?("..") || req.path.include?("//")
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |req|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "Rate limit exceeded. Please try again later." }.to_json]
    ]
  end
end
