class JsonWebToken
  SECRET_KEY = if Rails.env.production?
    Rails.application.credentials.secret_key_base || ENV.fetch("SECRET_KEY_BASE") { raise "SECRET_KEY_BASE must be set in production" }
  else
    Rails.application.credentials.secret_key_base || ENV.fetch("SECRET_KEY_BASE", Rails.application.secret_key_base || SecureRandom.hex(64))
  end
  ALGORITHM = "HS256"
  ACCESS_TOKEN_EXPIRE = 30.minutes
  REFRESH_TOKEN_EXPIRE = 7.days

  def self.encode(payload, exp = ACCESS_TOKEN_EXPIRE.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  def self.encode_refresh(payload)
    payload[:exp] = REFRESH_TOKEN_EXPIRE.from_now.to_i
    payload[:type] = "refresh"
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY, true, algorithm: ALGORITHM)[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
