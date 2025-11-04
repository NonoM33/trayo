module Api
  module V2
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [:register, :login]

      def register
        user = User.new(user_params)

        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render_success({
            token: token,
            user: user_serializer(user)
          }, status: :created)
        else
          render_error(user.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render_success({
            token: token,
            user: user_serializer(user)
          })
        else
          render_error("Invalid email or password", status: :unauthorized)
        end
      end

      def logout
        render_success({ message: "Logged out successfully" })
      end

      def refresh
        token = JsonWebToken.encode(user_id: current_user.id)
        render_success({
          token: token,
          user: user_serializer(current_user)
        })
      end

      def me
        render_success({ user: user_serializer(current_user) })
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
      end

      def user_serializer(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          mt5_api_token: user.mt5_api_token,
          commission_rate: user.commission_rate,
          is_admin: user.is_admin,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
    end
  end
end

