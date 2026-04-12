require 'rails_helper'

RSpec.describe "Api::Admin", type: :request do
  let(:tenant) { create(:tenant) }
  let(:admin) { create(:user, :admin, tenant: tenant) }
  let(:regular_user) { create(:user, tenant: tenant) }
  let(:admin_token) { JsonWebToken.encode(sub: admin.id) }
  let(:user_token) { JsonWebToken.encode(sub: regular_user.id) }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:user_headers) { { "Authorization" => "Bearer #{user_token}" } }

  describe "GET /api/admin/users" do
    it "returns users for admin" do
      create_list(:user, 3, tenant: tenant)
      get "/api/admin/users", headers: admin_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to be >= 3
    end

    it "returns forbidden for non-admin" do
      get "/api/admin/users", headers: user_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/admin/users/:id/suspend" do
    it "suspends a user" do
      post "/api/admin/users/#{regular_user.id}/suspend", headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(regular_user.reload.is_active).to be false
      expect(regular_user.suspension_until).to be_present
    end
  end

  describe "DELETE /api/admin/users/:id" do
    it "soft-deletes a user" do
      delete "/api/admin/users/#{regular_user.id}", headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(regular_user.reload.is_active).to be false
    end
  end
end
