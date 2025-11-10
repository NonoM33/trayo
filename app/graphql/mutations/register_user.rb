module Mutations
  class RegisterUser < BaseMutation
    description "Register a new user"

    argument :email, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true
    argument :first_name, String, required: true
    argument :last_name, String, required: true

    field :token, String, null: true
    field :user, Types::UserType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(email:, password:, password_confirmation:, first_name:, last_name:)
      user = User.new(
        email: email,
        password: password,
        password_confirmation: password_confirmation,
        first_name: first_name,
        last_name: last_name
      )

      if user.save
        token = JsonWebToken.encode(user_id: user.id)
        {
          token: token,
          user: user,
          errors: nil
        }
      else
        {
          token: nil,
          user: nil,
          errors: user.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

