# Handles JWT token encoding and decoding for API authentication.
# Tokens are signed using JWT_SECRET (or Rails secret_key_base fallback) and expire after JWT_EXPIRATION_HOURS.
class JwtService
  SECRET_KEY = ENV.fetch("JWT_SECRET") { Rails.application.credentials.secret_key_base }
  ALGORITHM = ENV.fetch("JWT_ALGORITHM", "HS256")
  EXPIRATION = ENV.fetch("JWT_EXPIRATION_HOURS", 24).to_i.hours

  # Encodes a payload into a JWT token.
  # @param payload [Hash] data to encode (typically { user_id: id })
  # @return [String] the encoded JWT token
  def self.encode(payload)
    payload[:exp] = EXPIRATION.from_now.to_i
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  # Decodes a JWT token and returns the payload.
  # @param token [String] the JWT token to decode
  # @return [HashWithIndifferentAccess, nil] decoded payload or nil if invalid
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError
    nil
  end
end
