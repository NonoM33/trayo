module Types
  class PaymentType < Types::BaseObject
    description "Payment type"

    field :id, ID, null: false
    field :amount, Float, null: false
    field :status, String, null: false
    field :payment_date, Types::DateTimeType, null: true
    field :description, String, null: true
    field :payment_method, String, null: true
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :user, Types::UserType, null: false
  end
end

