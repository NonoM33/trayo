module Mutations
  class CreateCredit < BaseMutation
    description "Create credit (admin only)"

    argument :user_id, ID, required: true
    argument :amount, Float, required: true
    argument :reason, String, required: false

    field :credit, Types::CreditType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(user_id:, amount:, reason: nil)
      admin = context[:current_user]
      return { credit: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless admin&.is_admin?

      user = User.find_by(id: user_id)
      return { credit: nil, errors: [{ field: "user_id", message: "User not found" }] } unless user

      credit = user.credits.build(
        amount: amount,
        reason: reason
      )

      if credit.save
        {
          credit: credit,
          errors: nil
        }
      else
        {
          credit: nil,
          errors: credit.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

