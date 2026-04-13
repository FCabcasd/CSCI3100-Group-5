require 'rails_helper'

RSpec.describe "Api::Bookings Check-In", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:admin) { create(:user, :admin, tenant: tenant) }
  let(:venue) { create(:venue, tenant: tenant) }
  let(:token) { JsonWebToken.encode(sub: user.id) }
  let(:admin_token) { JsonWebToken.encode(sub: admin.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }

  describe "POST /api/bookings/:id/check_in" do
    let(:booking) do
      create(:booking, user: user, venue: venue, status: :confirmed,
        start_time: Time.current,
        end_time: 2.hours.from_now)
    end

    it "checks in to a confirmed booking" do
      post "/api/bookings/#{booking.id}/check_in", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(booking.reload.checked_in_at).to be_present
    end

    it "rejects check-in for pending booking" do
      booking.update!(status: :pending)
      post "/api/bookings/#{booking.id}/check_in", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "rejects double check-in" do
      booking.update!(checked_in_at: Time.current)
      post "/api/bookings/#{booking.id}/check_in", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "allows admin to check in any booking" do
      post "/api/bookings/#{booking.id}/check_in", headers: admin_headers
      expect(response).to have_http_status(:ok)
    end

    it "denies check-in for another user's booking" do
      other_user = create(:user, tenant: tenant)
      other_token = JsonWebToken.encode(sub: other_user.id)
      other_headers = { "Authorization" => "Bearer #{other_token}" }
      post "/api/bookings/#{booking.id}/check_in", headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
