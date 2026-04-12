When("I request the user list") do
  json_get "/api/admin/users", headers: @auth_headers
end

Then("I should see a list of users") do
  expect(response.status).to eq(200)
  expect(response_json).to be_an(Array)
end

Given("a pending booking exists") do
  user = User.find_by(role: :user) || @current_user
  venue = Venue.first || Venue.create!(
    tenant: @tenant, name: "Test Venue", is_active: true,
    available_from: "08:00", available_until: "22:00"
  )
  @booking = Booking.create!(
    user: user,
    venue: venue,
    title: "Pending Booking",
    start_time: 3.days.from_now.change(hour: 14),
    end_time: 3.days.from_now.change(hour: 16),
    status: :pending,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

When("I confirm the booking") do
  json_post "/api/bookings/#{@booking.id}/confirm", headers: @auth_headers
end

Then("the booking status should be {string}") do |status|
  expect(response.status).to eq(200)
  expect(@booking.reload.status).to eq(status)
end

When("I suspend user {string}") do |username|
  user = User.find_by!(username: username)
  json_post "/api/admin/users/#{user.id}/suspend", headers: @auth_headers
end

Then("the user {string} should be suspended") do |username|
  user = User.find_by!(username: username)
  expect(user.reload.is_active).to be false
  expect(user.suspension_until).to be_present
end

Then("I should receive a forbidden error") do
  expect(response.status).to eq(403)
end
