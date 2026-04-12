module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      decoded = JsonWebToken.decode(token)

      if decoded && decoded[:type] != "refresh"
        user = User.find_by(id: decoded[:sub])
        user if user&.is_active
      end || reject_unauthorized_connection
    end
  end
end
