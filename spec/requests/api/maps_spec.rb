require 'rails_helper'

RSpec.describe "Api::Maps", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:token) { JsonWebToken.encode(sub: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/venues/:id/map" do
    context "when venue has coordinates" do
      let(:venue) { create(:venue, tenant: tenant, latitude: 22.4196, longitude: 114.2068) }

      it "returns google maps URL with coordinates" do
        get "/api/venues/#{venue.id}/map", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["google_maps_url"]).to include("google.com/maps")
        expect(json["venue_id"]).to eq(venue.id)
        expect(json["venue_name"]).to eq(venue.name)
        expect(json["latitude"]).to eq(22.4196)
        expect(json["longitude"]).to eq(114.2068)
      end
    end

    context "when venue has location but no coordinates" do
      let(:venue) { create(:venue, tenant: tenant, latitude: nil, longitude: nil, location: "Main Building, CUHK") }

      it "returns google maps URL with location query" do
        get "/api/venues/#{venue.id}/map", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["google_maps_url"]).to include("google.com/maps")
      end
    end

    context "when venue has no location data" do
      let(:venue) { create(:venue, tenant: tenant, latitude: nil, longitude: nil, location: nil) }

      it "returns unprocessable_entity" do
        get "/api/venues/#{venue.id}/map", headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Location not available")
      end
    end

    context "when venue does not exist" do
      it "returns not_found" do
        get "/api/venues/99999/map", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        venue = create(:venue, tenant: tenant)
        get "/api/venues/#{venue.id}/map"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
