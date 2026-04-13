Given("I have a confirmed booking for venue {string} starting now") do |venue_name|
  venue = Venue.find_by!(name: venue_name)
  @booking = Booking.create!(
    user: @current_user,
    venue: venue,
    title: "Check-in Test Booking",
    start_time: Time.current,
    end_time: 2.hours.from_now,
    status: :confirmed,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

Given("I have a pending booking for venue {string}") do |venue_name|
  venue = Venue.find_by!(name: venue_name)
  @booking = Booking.create!(
    user: @current_user,
    venue: venue,
    title: "Pending Booking",
    start_time: 2.days.from_now.change(hour: 10),
    end_time: 2.days.from_now.change(hour: 12),
    status: :pending,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

Given("the booking is already checked in") do
  @booking.update!(checked_in_at: Time.current)
end

When("I check in to the booking") do
  json_post "/api/bookings/#{@booking.id}/check_in", headers: @auth_headers
end

Then("the check-in should be successful") do
  expect(response.status).to eq(200)
  expect(response_json["success"]).to be true
  expect(@booking.reload.checked_in_at).to be_present
end
