require 'rails_helper'

RSpec.describe "Api::Tenants", type: :request do
  describe "GET /api/tenants" do
    it "returns active tenants without authentication" do
      active = create(:tenant, name: "CS Department", is_active: true)
      inactive = create(:tenant, name: "Old Dept", is_active: false)

      get "/api/tenants"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json.map { |t| t["name"] }
      expect(names).to include("CS Department")
      expect(names).not_to include("Old Dept")
    end

    it "returns tenants ordered by name" do
      create(:tenant, name: "Zebra Dept", is_active: true)
      create(:tenant, name: "Alpha Dept", is_active: true)

      get "/api/tenants"
      json = JSON.parse(response.body)
      expect(json.first["name"]).to eq("Alpha Dept")
      expect(json.last["name"]).to eq("Zebra Dept")
    end

    it "returns id and name for each tenant" do
      create(:tenant, name: "Test Dept", is_active: true)

      get "/api/tenants"
      json = JSON.parse(response.body)
      expect(json.first).to have_key("id")
      expect(json.first).to have_key("name")
    end
  end
end
