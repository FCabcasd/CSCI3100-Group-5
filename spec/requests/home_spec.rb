require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns success" do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /menu" do
    it "redirects when no referer" do
      get menu_path
      expect(response).to redirect_to(root_path)
    end

    it "renders menu when referer matches host" do
      get menu_path, headers: { "HTTP_REFERER" => "http://www.example.com/" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /catalog" do
    it "returns success" do
      get catalog_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /equipment" do
    it "returns success" do
      get equipment_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /user_bookings" do
    it "returns success" do
      get user_bookings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin_panel" do
    it "returns success" do
      get admin_panel_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /analytics" do
    it "returns success" do
      get analytics_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /profile" do
    it "returns success" do
      get profile_path
      expect(response).to have_http_status(:ok)
    end
  end
end
