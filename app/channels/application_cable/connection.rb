module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.headers["Authorization"]&.split(" ")&.last
      unless token
        reject_unauthorized_connection
        return nil
      end

      decoded = JsonWebToken.decode(token)
      unless decoded
        reject_unauthorized_connection
        return nil
      end

      user = User.find_by(id: decoded[:user_id])
      unless user
        reject_unauthorized_connection
        return nil
      end

      user
    end
  end
end

