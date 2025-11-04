module Mutations
  class CreatePayment < BaseMutation
    description "Create a payment"

    argument :amount, Float, required: true
    argument :description, String, required: false
    argument :payment_method, String, required: false
    argument :payment_date, Types::DateTimeType, required: false

    field :payment, Types::PaymentType, null: true
    field :errors, [Types::ErrorType], null: true

    def resolve(amount:, description: nil, payment_method: nil, payment_date: nil)
      user = context[:current_user]
      return { payment: nil, errors: [{ field: "base", message: "Unauthorized" }] } unless user

      payment = user.payments.build(
        amount: amount,
        description: description,
        payment_method: payment_method,
        payment_date: payment_date || Time.current,
        status: 'pending'
      )

      if payment.save
        {
          payment: payment,
          errors: nil
        }
      else
        {
          payment: nil,
          errors: payment.errors.map { |e| { field: e.attribute.to_s, message: e.full_message } }
        }
      end
    end
  end
end

