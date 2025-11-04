module Mutations
  class UpdatePassword < BaseMutation
    description "Update user password"

    argument :current_password, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true

    field :success, Boolean, null: false
    field :errors, [Types::ErrorType], null: true

    def resolve(current_password:, password:, password_confirmation:)
      user = context[:current_user]
      return { success: false, errors: [{ field: "base", message: "Unauthorized" }] } unless user

      unless user.authenticate(current_password)
        return {
          success: false,
          errors: [{ field: "current_password", message: "Current password is incorrect" }]
        }
      end

      user.password = password
      user.password_confirmation = password_confirmation

      if user.save
        {
          success: true,
          errors: nil
        }
      else
        {
          success: false,
          errors: user.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

