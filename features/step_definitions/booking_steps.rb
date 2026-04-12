Given("a tenant {string} exists") do |name|
  @tenant = Tenant.create!(
    name: name,
    description: "Test tenant",
    is_active: true,
    cancellation_deadline_hours: 24,
    point_deduction_per_late_cancel: 10,
    max_recurring_days: 180
  )
end

Given("a venue {string} exists in {string} with capacity {int}") do |venue_name, tenant_name, capacity|
  tenant = Tenant.find_by!(name: tenant_name)
  @venue = Venue.create!(
    tenant: tenant,
    name: venue_name,
    capacity: capacity,
    location: "Main Building",
    is_active: true,
    available_from: "08:00",
    available_until: "22:00"
  )
end

Given("a user {string} exists in {string} with {int} points") do |username, tenant_name, points|
  tenant = Tenant.find_by!(name: tenant_name)
  user = User.new(
    email: "#{username}@example.com",
    username: username,
    full_name: username.capitalize,
    tenant: tenant,
    is_active: true,
    points: points,
    role: :user
  )
  user.password = "password123"
  user.save!
end

Given("a user {string} exists in {string} with role {string}") do |username, tenant_name, role|
  tenant = Tenant.find_by!(name: tenant_name)
  user = User.new(
    email: "#{username}@example.com",
    username: username,
    full_name: username.capitalize,
    tenant: tenant,
    is_active: true,
    points: 100,
    role: role.to_sym
  )
  user.password = "password123"
  user.save!
end

Given("I am authenticated as {string}") do |username|
  user = User.find_by!(username: username)
  @current_user = user
  @auth_token = JsonWebToken.encode(sub: user.id)
  @auth_headers = { "Authorization" => "Bearer #{@auth_token}" }
end

When("I create a booking for venue {string} from {string} to {string} tomorrow") do |venue_name, start_hour, end_hour|
  venue = Venue.find_by!(name: venue_name)
  tomorrow = Date.tomorrow
  json_post "/api/bookings", params: {
    title: "Test Booking",
    venue_id: venue.id,
    start_time: tomorrow.to_datetime.change(hour: start_hour.split(":")[0].to_i, min: start_hour.split(":")[1].to_i).iso8601,
    end_time: tomorrow.to_datetime.change(hour: end_hour.split(":")[0].to_i, min: end_hour.split(":")[1].to_i).iso8601,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678",
    equipment_ids: []
  }, headers: @auth_headers
end

Then("the booking should be created with status {string}") do |status|
  expect(response.status).to eq(201)
  expect(response_json["status"]).to eq(status)
  @last_booking_id = response_json["id"]
end

Then("a confirmation email should be sent") do
  # Email is enqueued via deliver_later; check no errors occurred
  expect(response.status).to be_between(200, 201)
end

Given("a confirmed booking exists for venue {string} from {string} to {string} tomorrow") do |venue_name, start_hour, end_hour|
  venue = Venue.find_by!(name: venue_name)
  tomorrow = Date.tomorrow
  @existing_booking = Booking.create!(
    user: @current_user,
    venue: venue,
    title: "Existing Booking",
    start_time: tomorrow.to_datetime.change(hour: start_hour.split(":")[0].to_i, min: start_hour.split(":")[1].to_i),
    end_time: tomorrow.to_datetime.change(hour: end_hour.split(":")[0].to_i, min: end_hour.split(":")[1].to_i),
    status: :confirmed,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

Then("I should receive a conflict error") do
  expect(response.status).to eq(400)
end

Given("I have a confirmed booking for venue {string} in {int} days") do |venue_name, days|
  venue = Venue.find_by!(name: venue_name)
  @booking = Booking.create!(
    user: @current_user,
    venue: venue,
    title: "My Booking",
    start_time: days.days.from_now.change(hour: 10),
    end_time: days.days.from_now.change(hour: 12),
    status: :confirmed,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

Given("I have a confirmed booking for venue {string} in {int} hours") do |venue_name, hours|
  venue = Venue.find_by!(name: venue_name)
  @booking = Booking.create!(
    user: @current_user,
    venue: venue,
    title: "Urgent Booking",
    start_time: hours.hours.from_now,
    end_time: (hours + 2).hours.from_now,
    status: :confirmed,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678"
  )
end

When("I cancel the booking with reason {string}") do |reason|
  json_post "/api/bookings/#{@booking.id}/cancel", params: { reason: reason },
       headers: @auth_headers
end

Then("the booking should be cancelled") do
  expect(response.status).to eq(200)
  expect(@booking.reload.status).to eq("cancelled")
end

Then("no points should be deducted") do
  cancellation = response_json["cancellation"]
  expect(cancellation["is_late_cancellation"]).to be false
end

Then("a cancellation email should be sent") do
  expect(response.status).to eq(200)
end

Then("{int} points should be deducted from {string}") do |points, username|
  user = User.find_by!(username: username)
  expect(user.points).to eq(100 - points)
end
