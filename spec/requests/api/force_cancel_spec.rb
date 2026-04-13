require 'rails_helper'

RSpec.describe "Api::Admin Force Cancel", type: :request do
  let(:tenant) { create(:tenant) }
  let(:admin) { create(:user, :admin, tenant: tenant) }
  let(:user) { create(:user, tenant: tenant, points: 100) }
  let(:venue) { create(:venue, tenant: tenant) }
  let(:admin_token) { JsonWebToken.encode(sub: admin.id) }
  let(:user_token) { JsonWebToken.encode(sub: user.id) }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:user_headers) { { "Authorization" => "Bearer #{user_token}" } }

  describe "POST /api/admin/bookings/:id/force_cancel" do
    let(:booking) do
      create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: 1.hour.from_now,
        end_time: 3.hours.from_now)
    end

    it "force-cancels without point deduction" do
      post "/api/admin/bookings/#{booking.id}/force_cancel",
        params: { reason: "Emergency maintenance" },
        headers: admin_headers, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(booking.reload.status).to eq("cancelled")
      expect(user.reload.points).to eq(100) # No deduction
    end

    it "returns the cancellation details" do
      post "/api/admin/bookings/#{booking.id}/force_cancel",
        params: { reason: "Fire drill" },
        headers: admin_headers, as: :json
      json = JSON.parse(response.body)
      expect(json["cancellation"]["is_late_cancellation"]).to be false
      expect(json["cancellation"]["points_deducted"]).to eq(0)
    end

    it "rejects already cancelled booking" do
      booking.update!(status: :cancelled)
      post "/api/admin/bookings/#{booking.id}/force_cancel",
        headers: admin_headers
      expect(response).to have_http_status(:bad_request)
    end

    it "is forbidden for non-admin" do
      post "/api/admin/bookings/#{booking.id}/force_cancel",
        headers: user_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent booking" do
      post "/api/admin/bookings/99999/force_cancel",
        headers: admin_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
