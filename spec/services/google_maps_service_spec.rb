require 'rails_helper'

RSpec.describe GoogleMapsService do
  describe ".map_url_for" do
    it "returns coordinates url when latitude and longitude exist" do
      venue = build(:venue, latitude: 22.4, longitude: 114.2, location: "CUHK")
      url = described_class.map_url_for(venue)
      expect(url).to include("22.4,114.2")
    end

    it "returns search url when only location exists" do
      venue = build(:venue, latitude: nil, longitude: nil, location: "CUHK Room A")
      url = described_class.map_url_for(venue)
      expect(url).to include("google.com/maps/search")
    end
  end
end
