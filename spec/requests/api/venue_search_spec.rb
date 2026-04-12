require 'rails_helper'

RSpec.describe "Api::Venues Search", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:token) { JsonWebToken.encode(sub: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  before do
    create(:venue, tenant: tenant, name: "Lecture Theatre 1", location: "Main Building")
    create(:venue, tenant: tenant, name: "Seminar Room A", location: "Science Building")
    create(:venue, tenant: tenant, name: "Computer Lab", location: "Main Building")
    create(:venue, tenant: tenant, name: "Hidden Venue", is_active: false)
  end

  describe "GET /api/venues/search" do
    it "searches venues by name" do
      get "/api/venues/search", params: { q: "Lecture" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json[0]["name"]).to eq("Lecture Theatre 1")
    end

    it "searches venues by location" do
      get "/api/venues/search", params: { q: "Main Building" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "returns empty for no match" do
      get "/api/venues/search", params: { q: "Swimming Pool" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it "excludes inactive venues" do
      get "/api/venues/search", params: { q: "Hidden" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it "requires a search query" do
      get "/api/venues/search", params: { q: "" }, headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "is case-insensitive" do
      get "/api/venues/search", params: { q: "lecture" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
    end
  end
end
