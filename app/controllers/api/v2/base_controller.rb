module Api
  module V2
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      include CursorPagination
      include Filterable
      include Searchable

      before_action :authenticate_user!

      protected

      def authenticate_user!
        header = request.headers["Authorization"]
        return render json: { error: "Unauthorized" }, status: :unauthorized unless header.present?

        token = header.split(" ").last
        return render json: { error: "Unauthorized" }, status: :unauthorized unless token.present?

        decoded = JsonWebToken.decode(token)
        return render json: { error: "Unauthorized" }, status: :unauthorized unless decoded

        @current_user = User.find_by(id: decoded[:user_id])
        return render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end

      def render_error(message, status: :unprocessable_entity)
        render json: { error: message }, status: status
      end

      def render_success(data, status: :ok)
        render json: data, status: status
      end
    end
  end
end

