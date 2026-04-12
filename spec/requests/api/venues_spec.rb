require 'rails_helper'

RSpec.describe "Api::Venues", type: :request do
  let(:tenant) { create(:tenant) }
  let(:admin) { create(:user, :admin, tenant: tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:admin_token) { JsonWebToken.encode(sub: admin.id) }
  let(:user_token) { JsonWebToken.encode(sub: user.id) }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:user_headers) { { "Authorization" => "Bearer #{user_token}" } }

  describe "GET /api/venues" do
    it "lists active venues" do
      create_list(:venue, 3, tenant: tenant, is_active: true)
      create(:venue, tenant: tenant, is_active: false)
      get "/api/venues", headers: user_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end
  end

  describe "POST /api/venues" do
    let(:params) do
      {
        name: "New Venue",
        tenant_id: tenant.id,
        capacity: 100,
        location: "Building A"
      }
    end

    it "creates a venue as admin" do
      post "/api/venues", params: params, headers: admin_headers, as: :json
      expect(response).to have_http_status(:created)
    end

    it "returns forbidden for regular user" do
      post "/api/venues", params: params, headers: user_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/venues/:id" do
    let(:venue) { create(:venue, tenant: tenant) }

    it "soft-deletes a venue" do
      delete "/api/venues/#{venue.id}", headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(venue.reload.is_active).to be false
    end
  end
end
