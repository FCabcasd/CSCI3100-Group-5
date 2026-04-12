class AiConsultantService
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
    @client = nil
    api_key = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]
    @client = OpenAI::Client.new(access_token: api_key) if api_key.present?
  end

  def available?
    @client.present?
  end

  def answer_question(question:, user_context: {})
    return unavailable_response unless available?

    context_msg = ""
    if user_context.present?
      context_msg = "\n\nUser Context:\n- User: #{user_context[:name]}\n- Points: #{user_context[:points]}\n- Role: #{user_context[:role]}"
    end

    response = @client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: BOOKING_POLICY },
        { role: "user",   content: "#{context_msg}\n\nQuestion: #{question}" }
      ],
      max_tokens: 500,
      temperature: 0.7
    })

    { success: true, answer: response.dig("choices", 0, "message", "content") }
  rescue => e
    { success: false, answer: "Sorry, I encountered an error: #{e.message}" }
  end

  def recommend_venues(requirements:, tenant_id: nil)
    return unavailable_response unless available?

    venues = Venue.where(is_active: true)
    venues = venues.where(tenant_id: tenant_id) if tenant_id
    venue_list = venues.map { |v| "- #{v.name}: Capacity #{v.capacity || 'N/A'}, Location: #{v.location || 'N/A'}, Features: #{v.features || {}}" }

    prompt = "#{BOOKING_POLICY}\n\nAVAILABLE VENUES:\n#{venue_list.join("\n")}\n\nRecommend suitable venues."

    response = @client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: prompt },
        { role: "user",   content: "Requirements: #{requirements}" }
      ],
      max_tokens: 500,
      temperature: 0.7
    })

    { success: true, answer: response.dig("choices", 0, "message", "content"), venues_found: venues.count }
  rescue => e
    { success: false, answer: "Sorry, I encountered an error: #{e.message}" }
  end

  def check_booking_conflicts(venue_id:, start_time:, end_time:)
    return unavailable_response unless available?

    venue = Venue.find_by(id: venue_id)
    start_dt = Time.zone.parse(start_time)
    end_dt   = Time.zone.parse(end_time)

    conflicts = Booking.where(venue_id: venue_id)
                       .where(status: [:confirmed, :pending])
                       .where("start_time < ? AND end_time > ?", end_dt, start_dt)

    conflict_info = conflicts.empty? ? "No conflicts found!" : "Conflicts with #{conflicts.count} existing booking(s)"

    prompt = "#{BOOKING_POLICY}\n\nVenue: #{venue&.name}\n#{conflict_info}\n\nAnalyze this booking slot."

    response = @client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: prompt },
        { role: "user",   content: "Is this time slot available?" }
      ],
      max_tokens: 400,
      temperature: 0.7
    })

    {
      success: true,
      answer: response.dig("choices", 0, "message", "content"),
      has_conflicts: conflicts.any?,
      conflict_count: conflicts.count
    }
  rescue => e
    { success: false, answer: "Sorry, I encountered an error: #{e.message}" }
  end

  private

  def unavailable_response
    { success: false, answer: "AI consultant is not available. Please configure OPENAI_API_KEY." }
  end
end
