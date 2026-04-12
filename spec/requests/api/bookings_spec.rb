require 'rails_helper'

RSpec.describe "Api::Bookings", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:venue) { create(:venue, tenant: tenant) }
  let(:token) { JsonWebToken.encode(sub: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /api/bookings" do
    let(:params) do
      {
        title: "Team Meeting",
        venue_id: venue.id,
        start_time: 2.days.from_now.change(hour: 10).iso8601,
        end_time: 2.days.from_now.change(hour: 12).iso8601,
        contact_person: "John",
        contact_email: "john@example.com",
        contact_phone: "12345678",
        equipment_ids: []
      }
    end

    it "creates a booking" do
      post "/api/bookings", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("Team Meeting")
      expect(json["status"]).to eq("pending")
    end

    it "returns unauthorized without token" do
      post "/api/bookings", params: params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/bookings" do
    it "lists user's bookings" do
      create_list(:booking, 3, user: user, venue: venue)
      get "/api/bookings", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end
  end

  describe "POST /api/bookings/:id/cancel" do
    let(:booking) do
      create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: 3.days.from_now.change(hour: 10),
        end_time: 3.days.from_now.change(hour: 12))
    end

    it "cancels the booking" do
      post "/api/bookings/#{booking.id}/cancel", params: { reason: "Changed plans" },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(booking.reload.status).to eq("cancelled")
    end
  end

  describe "POST /api/bookings/:id/confirm" do
    let(:admin) { create(:user, :admin, tenant: tenant) }
    let(:admin_token) { JsonWebToken.encode(sub: admin.id) }
    let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
    let(:booking) { create(:booking, user: user, venue: venue, status: :pending) }

    it "confirms a booking as admin" do
      post "/api/bookings/#{booking.id}/confirm", headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(booking.reload.status).to eq("confirmed")
    end

    it "returns forbidden for regular user" do
      post "/api/bookings/#{booking.id}/confirm", headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
