module Mutations
  class LoginUser < BaseMutation
    description "Login user"

    argument :email, String, required: true
    argument :password, String, required: true

    field :token, String, null: true
    field :user, Types::UserType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(email:, password:)
      user = User.find_by(email: email)

      if user&.authenticate(password)
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
          errors: [{ field: "base", message: "Invalid email or password" }]
        }
      end
    end
  end
end

