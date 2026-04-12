Given("equipment {string} exists in {string}") do |name, tenant_name|
  tenant = Tenant.find_by!(name: tenant_name)
  Equipment.create!(
    tenant: tenant,
    name: name,
    description: "Test #{name}",
    quantity: 5,
    equipment_type: "general",
    status: "available",
    is_active: true
  )
end

When("I search for venues with query {string}") do |query|
  json_get "/api/venues/search?q=#{CGI.escape(query)}", headers: @auth_headers
end

When("I search for venues with empty query") do
  json_get "/api/venues/search?q=", headers: @auth_headers
end

When("I search for equipment with query {string}") do |query|
  json_get "/api/equipment/search?q=#{CGI.escape(query)}", headers: @auth_headers
end

Then("I should see {int} venue(s) in the results") do |count|
  expect(response.status).to eq(200)
  expect(response_json.length).to eq(count)
end

Then("I should see {int} equipment in the results") do |count|
  expect(response.status).to eq(200)
  expect(response_json.length).to eq(count)
end

Then("the results should include {string}") do |name|
  names = response_json.map { |r| r["name"] }
  expect(names).to include(name)
end

Then("I should receive a bad request error") do
  expect(response.status).to eq(400)
end
