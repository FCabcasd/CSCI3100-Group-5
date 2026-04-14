module Api
  class TenantsController < BaseController
    skip_before_action :authorize_request, only: [ :index ]

    def index
      tenants = Tenant.where(is_active: true).order(:name)
      render json: tenants.map { |t| { id: t.id, name: t.name } }
    end
  end
end
