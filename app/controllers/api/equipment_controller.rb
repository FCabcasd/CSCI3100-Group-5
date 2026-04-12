module Api
  class EquipmentController < BaseController
    before_action :require_tenant_admin!, only: [ :create, :update, :destroy ]

    def search
      query = params[:q].to_s.strip
      return render json: { error: "Search query required" }, status: :bad_request if query.blank?

      equipment = tenant_scope(Equipment).where(is_active: true)
                       .where("name LIKE :q OR description LIKE :q OR equipment_type LIKE :q",
                              q: "%#{sanitize_sql_like(query)}%")
                       .limit([ params.fetch(:limit, 20).to_i, 100 ].min)
      render json: equipment.map { |e| equipment_response(e) }
    end

    def index
      equipment = tenant_scope(Equipment).where(is_active: true)
                           .offset(params[:skip].to_i)
                           .limit([ params.fetch(:limit, 10).to_i, 100 ].min)
      render json: equipment.map { |e| equipment_response(e) }
    end

    def show
      eq = tenant_scope(Equipment).find(params[:id])
      render json: equipment_response(eq)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Equipment not found" }, status: :not_found
    end

    def create
      tenant = Tenant.find_by(id: params[:tenant_id])
      unless tenant
        return render json: { error: "Tenant not found" }, status: :not_found
      end

      unless @current_user.tenant_id == params[:tenant_id].to_i || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      eq = Equipment.new(equipment_params)
      if eq.save
        render json: equipment_response(eq), status: :created
      else
        render json: { errors: eq.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      eq = Equipment.find(params[:id])

      unless @current_user.tenant_id == eq.tenant_id || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      if eq.update(equipment_update_params)
        render json: equipment_response(eq)
      else
        render json: { errors: eq.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Equipment not found" }, status: :not_found
    end

    def destroy
      eq = Equipment.find(params[:id])

      unless @current_user.tenant_id == eq.tenant_id || @current_user.admin?
        return render json: { error: "Access denied" }, status: :forbidden
      end

      eq.update!(is_active: false)
      render json: { success: true, message: "Equipment deleted" }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Equipment not found" }, status: :not_found
    end

    private

    def equipment_params
      params.permit(:name, :description, :quantity, :equipment_type, :image_url, :tenant_id)
    end

    def equipment_update_params
      params.permit(:name, :description, :quantity, :equipment_type, :image_url)
    end

    def equipment_response(eq)
      {
        id: eq.id,
        tenant_id: eq.tenant_id,
        name: eq.name,
        description: eq.description,
        quantity: eq.quantity,
        equipment_type: eq.equipment_type,
        status: eq.status,
        image_url: eq.image_url,
        is_active: eq.is_active,
        created_at: eq.created_at,
        updated_at: eq.updated_at
      }
    end
  end
end
