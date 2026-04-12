module Api
  class AuthController < BaseController
    skip_before_action :authorize_request, only: [:register, :login, :refresh]

    def register
      if User.exists?(email: params[:email])
        return render json: { error: "Email already registered" }, status: :conflict
      end

      if User.exists?(username: params[:username])
        return render json: { error: "Username already taken" }, status: :conflict
      end

      user = User.new(
        email: params[:email],
        username: params[:username],
        full_name: params[:full_name]
      )
      user.password = params[:password]

      if user.save
        render json: user_response(user), status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def login
      user = User.find_by(email: params[:email])

      unless user&.authenticate(params[:password])
        return render json: { error: "Invalid email or password" }, status: :unauthorized
      end

      unless user.is_active
        return render json: { error: "Account is disabled" }, status: :forbidden
      end

      access_token  = JsonWebToken.encode(sub: user.id)
      refresh_token = JsonWebToken.encode_refresh(sub: user.id)

      render json: {
        access_token: access_token,
        refresh_token: refresh_token,
        token_type: "bearer",
        expires_in: 1800
      }
    end

    def refresh
      refresh_token = params[:refresh_token]
      unless refresh_token
        return render json: { error: "Missing refresh_token" }, status: :bad_request
      end

      payload = JsonWebToken.decode(refresh_token)
      unless payload && payload[:type] == "refresh"
        return render json: { error: "Invalid refresh_token" }, status: :unauthorized
      end

      user = User.find_by(id: payload[:sub])
      unless user&.is_active
        return render json: { error: "User not found or disabled" }, status: :unauthorized
      end

      access_token = JsonWebToken.encode(sub: user.id)

      render json: {
        access_token: access_token,
        refresh_token: refresh_token,
        token_type: "bearer",
        expires_in: 1800
      }
    end

    def me
      render json: user_response(@current_user)
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
