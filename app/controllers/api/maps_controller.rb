module Api
  class MapsController < BaseController
    def show
      venue = tenant_scope(Venue).find(params[:id])
      url = GoogleMapsService.map_url_for(venue)

      if url
        render json: {
          venue_id: venue.id,
          venue_name: venue.name,
          location: venue.location,
          latitude: venue.latitude,
          longitude: venue.longitude,
          google_maps_url: url
        }
      else
        render json: { error: "Location not available" }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Venue not found" }, status: :not_found
    end
  end
end
