require 'rails_helper'

RSpec.describe "Api::Equipment Search", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:token) { JsonWebToken.encode(sub: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  before do
    create(:equipment, tenant: tenant, name: "HD Projector", equipment_type: "AV")
    create(:equipment, tenant: tenant, name: "Wireless Microphone", equipment_type: "audio")
    create(:equipment, tenant: tenant, name: "Portable Speaker", equipment_type: "audio")
    create(:equipment, tenant: tenant, name: "Broken Projector", is_active: false)
  end

  describe "GET /api/equipment/search" do
    it "searches equipment by name" do
      get "/api/equipment/search", params: { q: "Projector" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json[0]["name"]).to eq("HD Projector")
    end

    it "searches equipment by type" do
      get "/api/equipment/search", params: { q: "audio" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "excludes inactive equipment" do
      get "/api/equipment/search", params: { q: "Broken" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it "requires a search query" do
      get "/api/equipment/search", params: { q: "" }, headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
