module Api
  class BaseController < ApplicationController
    skip_forgery_protection

    before_action :authorize_request

    private

    def authorize_request
      header = request.headers["Authorization"]
      token = header&.split(" ")&.last

      decoded = JsonWebToken.decode(token)
      if decoded.nil? || decoded[:type] == "refresh"
        render json: { error: "Invalid token" }, status: :unauthorized
        return
      end

      @current_user = User.find_by(id: decoded[:sub])
      unless @current_user
        render json: { error: "User not found" }, status: :unauthorized
        return
      end

      unless @current_user.is_active
        render json: { error: "Inactive user" }, status: :unauthorized
        return
      end

      if @current_user.suspended?
        render json: { error: "User account is suspended" }, status: :forbidden
        return
      end
    end

    def require_admin!
      unless @current_user.admin?
        render json: { error: "Admin access required" }, status: :forbidden
      end
    end

    def require_tenant_admin!
      unless @current_user.admin? || @current_user.tenant_admin?
        render json: { error: "Tenant admin access required" }, status: :forbidden
      end
    end

    def current_tenant_id
      @current_user.tenant_id
    end

    def tenant_scope(model)
      if @current_user.admin?
        model.all
      else
        model.where(tenant_id: current_tenant_id)
      end
    end
  end
end
