Given("user {string} has a confirmed booking for venue {string} in {int} hours") do |username, venue_name, hours|
  user = User.find_by!(username: username)
  venue = Venue.find_by!(name: venue_name)
  @force_cancel_booking = Booking.create!(
    user: user,
    venue: venue,
    title: "Booking to force cancel",
    start_time: hours.hours.from_now,
    end_time: (hours + 2).hours.from_now,
    status: :confirmed,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

Given("user {string} has a confirmed booking for venue {string} in {int} days") do |username, venue_name, days|
  user = User.find_by!(username: username)
  venue = Venue.find_by!(name: venue_name)
  @force_cancel_booking = Booking.create!(
    user: user,
    venue: venue,
    title: "Booking to force cancel",
    start_time: days.days.from_now.change(hour: 10),
    end_time: days.days.from_now.change(hour: 12),
    status: :confirmed,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

When("I force cancel the booking with reason {string}") do |reason|
  json_post "/api/admin/bookings/#{@force_cancel_booking.id}/force_cancel",
    params: { reason: reason }, headers: @auth_headers
end

When("I try to force cancel the booking") do
  json_post "/api/admin/bookings/#{@force_cancel_booking.id}/force_cancel",
    headers: @auth_headers
end

Then("the force-cancelled booking should be cancelled") do
  expect(response.status).to eq(200)
  expect(@force_cancel_booking.reload.status).to eq("cancelled")
end

Then("no points should be deducted from {string}") do |username|
  user = User.find_by!(username: username)
  expect(user.reload.points).to eq(100)
end
