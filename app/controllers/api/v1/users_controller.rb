module Api
  module V1
    class UsersController < ApplicationController
      include Authenticable
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_request, only: [:index]

      def index
        users = User.all.order(created_at: :desc)
        
        render json: {
          users: users.map do |user|
            {
              id: user.id,
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name,
              mt5_api_token: user.mt5_api_token,
              accounts_count: user.mt5_accounts.count,
              created_at: user.created_at
            }
          end,
          total: users.count
        }, status: :ok
      end

      def me
        render json: {
          user: {
            id: current_user.id,
            email: current_user.email,
            first_name: current_user.first_name,
            last_name: current_user.last_name,
            mt5_api_token: current_user.mt5_api_token,
            mt5_accounts: current_user.mt5_accounts.map do |account|
              {
                id: account.id,
                mt5_id: account.mt5_id,
                account_name: account.account_name,
                balance: account.balance
              }
            end
          }
        }, status: :ok
      end

      def destroy
        user = User.find_by(id: params[:id])
        
        unless user
          render json: { error: "User not found" }, status: :not_found
          return
        end

        if current_user.id != user.id
          render json: { error: "Unauthorized" }, status: :unauthorized
          return
        end

        user.destroy
        render json: { message: "User deleted successfully" }, status: :ok
      end
    end
  end
end

