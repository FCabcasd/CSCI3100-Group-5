module Api
  class AdminController < BaseController
    before_action :require_admin!

    def users
      scope = User.where(is_active: true)
      if params[:role].present?
        roles = Array(params[:role])
        scope = scope.where(role: roles.map { |r| User.roles[r] }.compact)
      end
      scope = scope.offset(params[:skip].to_i)

      render json: scope.map { |u| user_response(u) }
    end

    def suspend_user
      user = User.find(params[:id])
      UserService.suspend_user(user: user)
      render json: user_response(user)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end

    def delete_user
      user = User.find(params[:id])
      user.update!(is_active: false)
      render json: { success: true, message: "User deleted" }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end

    private

    def user_response(user)
      {
        id: user.id,
        email: user.email,
        username: user.username,
        full_name: user.full_name,
        role: user.role,
        tenant_id: user.tenant_id,
        is_active: user.is_active,
        points: user.points,
        created_at: user.created_at
      }
    end
  end
end
