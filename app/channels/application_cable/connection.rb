module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Try JWT token first (from cookies or params)
      token = cookies["jwt_token"] || request.params["token"]
      
      if token.present?
        decoded = JsonWebToken.decode(token)
        if verified_user = User.find_by(id: decoded["user_id"])
          return verified_user
        end
      end
      
      # Fall back to session-based auth
      if verified_user = User.find_by(id: cookies.encrypted[:user_id])
        return verified_user
      end
      
      reject_unauthorized_connection
    rescue JWT::DecodeError
      reject_unauthorized_connection
    end
  end
end
