When("I register with email {string} and username {string} and password {string}") do |email, username, password|
  json_post "/api/auth/register", params: {
    email: email,
    username: username,
    full_name: "Test User",
    password: password
  }
end

Then("I should receive a successful registration response") do
  expect(response.status).to eq(201)
end

Then("the response should contain my user details") do
  json = response_json
  # user_response returns email/username at top level
  expect(json["email"]).to be_present
  expect(json["username"]).to be_present
end

Given("a user exists with email {string} and password {string}") do |email, password|
  user = User.new(
    email: email,
    username: email.split("@").first,
    full_name: "Test User",
    is_active: true,
    points: 100
  )
  user.password = password
  user.save!
end

When("I login with email {string} and password {string}") do |email, password|
  json_post "/api/auth/login", params: { email: email, password: password }
end

Then("I should receive a valid access token") do
  expect(response_json["access_token"]).to be_present
end

Then("I should receive a valid refresh token") do
  expect(response_json["refresh_token"]).to be_present
end

Then("I should receive an unauthorized error") do
  expect(response.status).to eq(401)
end

When("I request my profile without a token") do
  json_get "/api/auth/me"
end
