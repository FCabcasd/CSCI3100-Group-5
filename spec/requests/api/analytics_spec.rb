require 'rails_helper'

RSpec.describe "Api::Analytics", type: :request do
  let(:tenant) { create(:tenant) }
  let(:admin) { create(:user, :admin, tenant: tenant) }
  let(:venue) { create(:venue, tenant: tenant) }
  let(:token) { JsonWebToken.encode(sub: admin.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/analytics/bookings/stats" do
    it "returns booking statistics" do
      create(:booking, user: admin, venue: venue, status: :pending)
      create(:booking, user: admin, venue: venue, status: :confirmed)
      create(:booking, user: admin, venue: venue, status: :cancelled)

      get "/api/analytics/bookings/stats", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["total_bookings"]).to eq(3)
      expect(json["pending_bookings"]).to eq(1)
      expect(json["confirmed_bookings"]).to eq(1)
      expect(json["cancelled_bookings"]).to eq(1)
    end
  end

  describe "GET /api/analytics/venues/usage" do
    it "returns venue usage data" do
      create_list(:booking, 2, user: admin, venue: venue)

      get "/api/analytics/venues/usage", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.first["venue_id"]).to eq(venue.id)
      expect(json.first["booking_count"]).to eq(2)
    end
  end

  describe "GET /api/analytics/peak-times" do
    it "returns peak time data" do
      create(:booking,
        user: admin,
        venue: venue,
        status: :confirmed,
        start_time: Time.current.change(hour: 10),
        end_time: Time.current.change(hour: 12)
      )

      get "/api/analytics/peak-times", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["hourly_peak_times"]).to be_present
      expect(json["weekday_peak_times"]).to be_present
    end
  end
end