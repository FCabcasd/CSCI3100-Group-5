require 'rails_helper'

RSpec.describe "Api::Auth", type: :request do
  describe "POST /api/auth/register" do
    let(:params) do
      {
        email: "newuser@example.com",
        username: "newuser",
        full_name: "New User",
        password: "password123"
      }
    end

    it "registers a new user" do
      post "/api/auth/register", params: params, as: :json
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["email"]).to eq("newuser@example.com")
      expect(json["username"]).to eq("newuser")
      expect(json["points"]).to eq(100)
    end

    it "returns conflict for duplicate email" do
      create(:user, email: "newuser@example.com")
      post "/api/auth/register", params: params, as: :json
      expect(response).to have_http_status(:conflict)
    end

    it "returns conflict for duplicate username" do
      create(:user, username: "newuser")
      post "/api/auth/register", params: params, as: :json
      expect(response).to have_http_status(:conflict)
    end
  end

  describe "POST /api/auth/login" do
    let(:user) { create(:user) }

    before do
      user.password = "password123"
      user.save!
    end

    it "returns tokens for valid credentials" do
      post "/api/auth/login", params: { email: user.email, password: "password123" }, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["access_token"]).to be_present
      expect(json["refresh_token"]).to be_present
      expect(json["token_type"]).to eq("bearer")
    end

    it "returns unauthorized for wrong password" do
      post "/api/auth/login", params: { email: user.email, password: "wrong" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns forbidden for inactive user" do
      user.update!(is_active: false)
      post "/api/auth/login", params: { email: user.email, password: "password123" }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/auth/me" do
    let(:user) { create(:user) }
    let(:token) { JsonWebToken.encode(sub: user.id) }

    it "returns current user info" do
      get "/api/auth/me", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(user.id)
      expect(json["email"]).to eq(user.email)
    end

    it "returns unauthorized without token" do
      get "/api/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/auth/refresh" do
    let(:user) { create(:user) }

    it "refreshes access token with valid refresh token" do
      refresh_token = JsonWebToken.encode_refresh(sub: user.id)
      post "/api/auth/refresh", params: { refresh_token: refresh_token }, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["access_token"]).to be_present
      expect(json["token_type"]).to eq("bearer")
    end

    it "returns bad_request when refresh_token is missing" do
      post "/api/auth/refresh", as: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "returns unauthorized for invalid refresh token" do
      post "/api/auth/refresh", params: { refresh_token: "invalid.token.here" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for access token used as refresh" do
      access_token = JsonWebToken.encode(sub: user.id)
      post "/api/auth/refresh", params: { refresh_token: access_token }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for disabled user" do
      user.update!(is_active: false)
      refresh_token = JsonWebToken.encode_refresh(sub: user.id)
      post "/api/auth/refresh", params: { refresh_token: refresh_token }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
