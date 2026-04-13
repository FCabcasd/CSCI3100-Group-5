class Rack::Attack
  # Throttle login attempts by IP
  throttle("auth/login/ip", limit: 10, period: 60.seconds) do |req|
    req.ip if req.path == "/api/auth/login" && req.post?
  end

  # Throttle login attempts by email parameter
  throttle("auth/login/email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/api/auth/login" && req.post?
      req.params.dig("email")&.to_s&.downcase&.strip
    end
  end

  # Throttle registration attempts by IP
  throttle("auth/register/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/api/auth/register" && req.post?
  end

  # Throttle token refresh by IP
  throttle("auth/refresh/ip", limit: 20, period: 60.seconds) do |req|
    req.ip if req.path == "/api/auth/refresh" && req.post?
  end

  # General API rate limit per IP
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |_request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Rate limit exceeded. Try again later." }.to_json ] ]
  end
end
