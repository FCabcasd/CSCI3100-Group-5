require 'rails_helper'

RSpec.describe "Api::Equipment", type: :request do
  let(:tenant) { create(:tenant) }
  let(:other_tenant) { create(:tenant, name: "Other Dept") }
  let(:admin) { create(:user, :admin, tenant: tenant) }
  let(:tenant_admin) { create(:user, :tenant_admin, tenant: tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:other_user) { create(:user, :tenant_admin, tenant: other_tenant) }

  let(:admin_token) { JsonWebToken.encode(sub: admin.id) }
  let(:tenant_admin_token) { JsonWebToken.encode(sub: tenant_admin.id) }
  let(:user_token) { JsonWebToken.encode(sub: user.id) }
  let(:other_token) { JsonWebToken.encode(sub: other_user.id) }

  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:tenant_admin_headers) { { "Authorization" => "Bearer #{tenant_admin_token}" } }
  let(:user_headers) { { "Authorization" => "Bearer #{user_token}" } }
  let(:other_headers) { { "Authorization" => "Bearer #{other_token}" } }

  describe "GET /api/equipment" do
    it "lists active equipment" do
      create_list(:equipment, 3, tenant: tenant, is_active: true)
      create(:equipment, tenant: tenant, is_active: false)
      get "/api/equipment", headers: user_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end

    it "supports pagination" do
      create_list(:equipment, 5, tenant: tenant)
      get "/api/equipment", params: { skip: 2, limit: 2 }, headers: user_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end
  end

  describe "GET /api/equipment/:id" do
    it "returns equipment details" do
      equip = create(:equipment, tenant: tenant)
      get "/api/equipment/#{equip.id}", headers: user_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq(equip.name)
    end

    it "returns 404 for missing equipment" do
      get "/api/equipment/99999", headers: user_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/equipment" do
    let(:params) do
      {
        name: "Projector",
        tenant_id: tenant.id,
        quantity: 5,
        equipment_type: "AV",
        description: "HD Projector"
      }
    end

    it "allows tenant_admin to create equipment" do
      post "/api/equipment", params: params, headers: tenant_admin_headers, as: :json
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Projector")
    end

    it "allows admin to create equipment" do
      post "/api/equipment", params: params, headers: admin_headers, as: :json
      expect(response).to have_http_status(:created)
    end

    it "forbids regular user from creating equipment" do
      post "/api/equipment", params: params, headers: user_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids tenant_admin from another tenant" do
      post "/api/equipment", params: params, headers: other_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/equipment/:id" do
    let!(:equip) { create(:equipment, tenant: tenant) }

    it "allows tenant_admin to update" do
      patch "/api/equipment/#{equip.id}", params: { name: "Updated" }, headers: tenant_admin_headers, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Updated")
    end

    it "forbids tenant_admin from another tenant" do
      patch "/api/equipment/#{equip.id}", params: { name: "Hacked" }, headers: other_headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/equipment/:id" do
    let!(:equip) { create(:equipment, tenant: tenant) }

    it "soft deletes equipment" do
      delete "/api/equipment/#{equip.id}", headers: tenant_admin_headers
      expect(response).to have_http_status(:ok)
      expect(equip.reload.is_active).to be false
    end

    it "forbids tenant_admin from another tenant" do
      delete "/api/equipment/#{equip.id}", headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
