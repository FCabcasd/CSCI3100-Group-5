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

  describe "GET /api/bookings/:id" do
    let(:booking) { create(:booking, user: user, venue: venue) }

    it "returns booking details" do
      get "/api/bookings/#{booking.id}", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(booking.id)
      expect(json["venue"]).to be_present
      expect(json["user"]).to be_present
    end

    it "returns not_found for non-existent booking" do
      get "/api/bookings/99999", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns forbidden for other user's booking" do
      other_user = create(:user, tenant: tenant)
      other_booking = create(:booking, user: other_user, venue: venue)
      get "/api/bookings/#{other_booking.id}", headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it "allows admin to view any booking" do
      admin = create(:user, :admin, tenant: tenant)
      admin_token = JsonWebToken.encode(sub: admin.id)
      other_user = create(:user, tenant: tenant)
      other_booking = create(:booking, user: other_user, venue: venue)
      get "/api/bookings/#{other_booking.id}", headers: { "Authorization" => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/bookings/create_recurring" do
    let(:start_time) { 2.days.from_now.change(hour: 14) }
    let(:recurring_params) do
      {
        title: "Weekly Standup",
        venue_id: venue.id,
        start_time: start_time.iso8601,
        end_time: 2.days.from_now.change(hour: 15).iso8601,
        contact_person: "Jane",
        contact_email: "jane@example.com",
        contact_phone: "87654321",
        recurrence_pattern: "weekly",
        recurrence_end_date: (start_time + 3.weeks).to_date.to_s,
        equipment_ids: []
      }
    end

    it "creates recurring bookings" do
      post "/api/bookings/create_recurring", params: recurring_params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json.length).to be >= 2
    end

    it "returns bad request for invalid pattern" do
      recurring_params[:recurrence_pattern] = "biweekly"
      post "/api/bookings/create_recurring", params: recurring_params, headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/bookings/:id/cancel edge cases" do
    it "returns not_found for non-existent booking" do
      post "/api/bookings/99999/cancel", headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns bad_request for already cancelled booking" do
      booking = create(:booking, user: user, venue: venue, status: :cancelled)
      post "/api/bookings/#{booking.id}/cancel", headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end
end
