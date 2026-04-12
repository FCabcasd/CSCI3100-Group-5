module Api
  class VenuesController < BaseController
    before_action :require_tenant_admin!, only: [ :create, :update, :destroy ]

    def index
      venues = tenant_scope(Venue).where(is_active: true)
                    .offset(params[:skip].to_i)
                    .limit([ params.fetch(:limit, 10).to_i, 100 ].min)
      render json: venues.map { |v| venue_response(v) }
    end

    def show
      venue = tenant_scope(Venue).find(params[:id])
      render json: venue_response(venue)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Venue not found" }, status: :not_found
    end

    def create
      tenant = Tenant.find_by(id: params[:tenant_id])
      unless tenant
        return render json: { error: "Tenant not found" }, status: :not_found
      end

      unless @current_user.tenant_id == params[:tenant_id].to_i || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      venue = Venue.new(venue_params)
      if venue.save
        render json: venue_response(venue), status: :created
      else
        render json: { errors: venue.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      venue = Venue.find(params[:id])

      unless @current_user.tenant_id == venue.tenant_id || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      if venue.update(venue_update_params)
        render json: venue_response(venue)
      else
        render json: { errors: venue.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Venue not found" }, status: :not_found
    end

    def destroy
      venue = Venue.find(params[:id])

      unless @current_user.tenant_id == venue.tenant_id || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      venue.update!(is_active: false)
      render json: { success: true, message: "Venue deleted" }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Venue not found" }, status: :not_found
    end

    private

    def venue_params
      params.permit(:name, :description, :capacity, :location,
                     :latitude, :longitude, :image_url,
                     :available_from, :available_until, :tenant_id,
                     features: {})
    end

    def venue_update_params
      params.permit(:name, :description, :capacity, :location,
                     :latitude, :longitude, :image_url,
                     :available_from, :available_until,
                     features: {})
    end

    def venue_response(venue)
      {
        id: venue.id,
        tenant_id: venue.tenant_id,
        name: venue.name,
        description: venue.description,
        capacity: venue.capacity,
        location: venue.location,
        latitude: venue.latitude,
        longitude: venue.longitude,
        features: venue.features,
        image_url: venue.image_url,
        available_from: venue.available_from,
        available_until: venue.available_until,
        is_active: venue.is_active,
        created_at: venue.created_at,
        updated_at: venue.updated_at
      }
    end
  end
end
