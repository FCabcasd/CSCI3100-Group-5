require 'rails_helper'

RSpec.describe "Api::Ai", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:token) { JsonWebToken.encode(sub: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/ai/status" do
    it "returns AI availability status" do
      get "/api/ai/status", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("available")
      expect(json).to have_key("message")
    end
  end

  describe "POST /api/ai/ask" do
    it "returns unavailable when no API key configured" do
      post "/api/ai/ask", params: { question: "What are the booking rules?" }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be false
      expect(json["answer"]).to include("not available")
    end
  end

  describe "POST /api/ai/recommend-venues" do
    it "returns unavailable when no API key configured" do
      post "/api/ai/recommend-venues", params: { requirements: "Room for 50 people" }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be false
    end
  end

  describe "POST /api/ai/check-conflicts" do
    let!(:venue) { create(:venue, tenant: tenant) }

    it "returns unavailable when no API key configured" do
      post "/api/ai/check-conflicts", params: {
        venue_id: venue.id,
        start_time: 1.day.from_now.iso8601,
        end_time: (1.day.from_now + 2.hours).iso8601
      }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be false
    end
  end

  describe "authentication" do
    it "requires authentication" do
      get "/api/ai/status"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
