When("I create a weekly recurring booking for venue {string} for {int} weeks") do |venue_name, weeks|
  venue = Venue.find_by!(name: venue_name)
  start_date = Date.tomorrow
  json_post "/api/bookings/create_recurring", params: {
    title: "Weekly Meeting",
    venue_id: venue.id,
    start_time: start_date.to_datetime.change(hour: 14, min: 0).iso8601,
    end_time: start_date.to_datetime.change(hour: 16, min: 0).iso8601,
    recurrence_pattern: "weekly",
    recurrence_end_date: (start_date + (weeks - 1).weeks).iso8601,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678",
    equipment_ids: []
  }, headers: @auth_headers
end

When("I create a daily recurring booking for venue {string} for {int} days") do |venue_name, days|
  venue = Venue.find_by!(name: venue_name)
  start_date = Date.tomorrow
  json_post "/api/bookings/create_recurring", params: {
    title: "Daily Meeting",
    venue_id: venue.id,
    start_time: start_date.to_datetime.change(hour: 10, min: 0).iso8601,
    end_time: start_date.to_datetime.change(hour: 12, min: 0).iso8601,
    recurrence_pattern: "daily",
    recurrence_end_date: (start_date + (days - 1).days).iso8601,
    contact_person: "Test",
    contact_email: "test@example.com",
    contact_phone: "12345678",
    equipment_ids: []
  }, headers: @auth_headers
end

Then("{int} bookings should be created") do |count|
  expect(response.status).to eq(201), "Expected 201 but got #{response.status}: #{response.body}"
  expect(response_json.length).to eq(count)
end

Then("at least {int} bookings should be created") do |min_count|
  expect(response.status).to eq(201)
  expect(response_json.length).to be >= min_count
end

Then("all bookings should have status {string}") do |status|
  response_json.each do |booking|
    expect(booking["status"]).to eq(status)
  end
end
