module Api
  class VenuesController < BaseController
    skip_before_action :authorize_request, only: [ :browse, :bookings ]
    before_action :require_tenant_admin!, only: [ :create, :update, :destroy ]

    # Public browse — no tenant scoping, all active venues
    def browse
      venues = Venue.where(is_active: true)
      if params[:q].present?
        q = "%#{sanitize_sql_like(params[:q].to_s.strip)}%"
        venues = venues.where("name LIKE :q OR location LIKE :q OR description LIKE :q", q: q)
      end
      venues = venues.offset(params[:skip].to_i)
                     .limit([ params.fetch(:limit, 20).to_i, 100 ].min)
      render json: venues.map { |v| venue_response(v) }
    end

    def search
      query = params[:q].to_s.strip
      return render json: { error: "Search query required" }, status: :bad_request if query.blank?

      venues = tenant_scope(Venue).where(is_active: true)
                    .where("name LIKE :q OR location LIKE :q OR description LIKE :q",
                           q: "%#{sanitize_sql_like(query)}%")
                    .limit([ params.fetch(:limit, 20).to_i, 100 ].min)
      render json: venues.map { |v| venue_response(v) }
    end

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

    # Public endpoint: view all bookings for a venue (calendar view)
    def bookings
      venue = Venue.where(is_active: true).find(params[:id])
      bookings = venue.bookings
                      .where(status: [ :pending, :confirmed ])
                      .where("end_time > ?", Time.current - 30.days)
                      .includes(:venue, :user, :equipment_list)
                      .order(start_time: :asc)
                      .limit(200)

      render json: bookings.map { |b|
        {
          id: b.id,
          title: b.title,
          start_time: b.start_time,
          end_time: b.end_time,
          status: b.status,
          venue_name: b.venue&.name,
          user_name: b.user&.username,
          equipment_names: b.equipment_list.map(&:name),
          remarks: b.description
        }
      }
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
