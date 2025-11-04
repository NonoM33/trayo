module Mutations
  class UpdateProfile < BaseMutation
    description "Update user profile"

    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :email, String, required: false

    field :user, Types::UserType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(first_name: nil, last_name: nil, email: nil)
      user = context[:current_user]
      return { user: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless user

      user.first_name = first_name if first_name.present?
      user.last_name = last_name if last_name.present?
      user.email = email if email.present?

      if user.save
        {
          user: user,
          errors: nil
        }
      else
        {
          user: nil,
          errors: user.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

