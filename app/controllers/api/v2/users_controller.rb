module Api
  module V2
    class UsersController < BaseController
      def me
        render_success({ user: user_serializer(current_user) })
      end

      def update
        if current_user.update(user_params)
          render_success({ user: user_serializer(current_user.reload) })
        else
          render_error(current_user.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      def update_password
        unless current_user.authenticate(params[:current_password])
          return render_error("Current password is incorrect", status: :unprocessable_entity)
        end

        current_user.password = params[:password]
        current_user.password_confirmation = params[:password_confirmation]

        if current_user.save
          render_success({ message: "Password updated successfully" })
        else
          render_error(current_user.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      def destroy
        if current_user.destroy
          render_success({ message: "Account deleted successfully" })
        else
          render_error("Failed to delete account", status: :unprocessable_entity)
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email)
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

