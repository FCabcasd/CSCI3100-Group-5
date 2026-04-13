require "net/http"
require "json"
require "uri"

class AiConsultantService
  GEMINI_MODEL = "gemini-2.5-flash-lite"
  GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/#{GEMINI_MODEL}:generateContent".freeze

  BOOKING_POLICY = <<~POLICY
    You are a helpful assistant for the CUHK Venue & Equipment Booking System.

    ## Booking Rules:
    1. Users can create bookings for venues and equipment
    2. Each user has points (starting at 100 points)
    3. Late cancellation (within 24 hours of start time) results in 10 point deduction
    4. If points fall below 10, user cannot make new bookings
    5. Users with 0 points or below will be suspended

    ## Venue Information:
    - Venues have capacity, location, and features
    - Venues are scoped to tenants (departments)
    - Each venue has available_from and available_until times

    ## Equipment:
    - Equipment can be booked alongside venues
    - Equipment availability is checked for conflicts

    ## Booking Process:
    1. Create booking with venue_id, start_time, end_time, title
    2. System checks for time conflicts
    3. Booking starts in "pending" status
    4. Admin confirms booking to change status to "confirmed"
    5. User or admin can cancel booking

    ## User Roles:
    - admin: Full system access
    - tenant_admin: Manage venues and confirm bookings within tenant
    - user: Create and manage own bookings

    Answer questions based on the above policy. Be helpful, concise, and accurate.
  POLICY

  def initialize
    @api_key = ENV["GEMINI_API_KEY"]
  end

  def available?
    @api_key.present?
  end

  def answer_question(question:, user_context: {})
    return unavailable_response unless available?

    context_msg = ""
    if user_context.present?
      context_msg = "\n\nUser Context:\n- User: #{user_context[:name]}\n- Points: #{user_context[:points]}\n- Role: #{user_context[:role]}"
    end

    prompt = "#{BOOKING_POLICY}#{context_msg}\n\nQuestion: #{question}"
    result = call_gemini(prompt)
    result
  end

  def recommend_venues(requirements:, tenant_id: nil)
    return unavailable_response unless available?

    venues = Venue.where(is_active: true)
    venues = venues.where(tenant_id: tenant_id) if tenant_id
    venue_list = venues.map { |v| "- #{v.name}: Capacity #{v.capacity || 'N/A'}, Location: #{v.location || 'N/A'}, Features: #{v.features || {}}" }

    prompt = "#{BOOKING_POLICY}\n\nAVAILABLE VENUES:\n#{venue_list.join("\n")}\n\nRecommend suitable venues for: #{requirements}"
    result = call_gemini(prompt)
    result.merge(venues_found: venues.count)
  end

  def check_booking_conflicts(venue_id:, start_time:, end_time:)
    return unavailable_response unless available?

    venue = Venue.find_by(id: venue_id)
    start_dt = Time.zone.parse(start_time)
    end_dt   = Time.zone.parse(end_time)

    conflicts = Booking.where(venue_id: venue_id)
                       .where(status: [ :confirmed, :pending ])
                       .where("start_time < ? AND end_time > ?", end_dt, start_dt)

    conflict_info = conflicts.empty? ? "No conflicts found!" : "Conflicts with #{conflicts.count} existing booking(s)"

    prompt = "#{BOOKING_POLICY}\n\nVenue: #{venue&.name}\n#{conflict_info}\n\nAnalyze this booking slot. Is this time slot available?"
    result = call_gemini(prompt)
    result.merge(has_conflicts: conflicts.any?, conflict_count: conflicts.count)
  end

  private

  def call_gemini(prompt)
    uri = URI("#{GEMINI_URL}?key=#{@api_key}")
    body = {
      contents: [ { parts: [ { text: prompt } ] } ],
      generationConfig: { maxOutputTokens: 500, temperature: 0.7 }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    response = http.request(request)
    data = JSON.parse(response.body)

    if response.code.to_i == 200
      text = data.dig("candidates", 0, "content", "parts", 0, "text")
      { success: true, answer: text || "No response generated." }
    elsif response.code.to_i == 429
      { success: false, answer: "AI service is temporarily rate-limited. Please wait a moment and try again." }
    else
      error_msg = data.dig("error", "message") || "Unknown error"
      Rails.logger.error("Gemini API error: #{response.code} - #{error_msg}")
      { success: false, answer: "AI service encountered an error. Please try again later." }
    end
  rescue Net::OpenTimeout, Net::ReadTimeout
    { success: false, answer: "AI service timed out. Please try again." }
  rescue => e
    Rails.logger.error("Gemini API exception: #{e.message}")
    { success: false, answer: "AI service encountered an error. Please try again later." }
  end

  def unavailable_response
    { success: false, answer: "AI consultant is not available. Please configure GEMINI_API_KEY." }
  end
end
