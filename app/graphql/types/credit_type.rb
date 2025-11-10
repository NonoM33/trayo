module Types
  class CreditType < Types::BaseObject
    description "Credit type"

    field :id, ID, null: false
    field :amount, Float, null: false
    field :reason, String, null: true
    field :created_at, Types::DateTimeType, null: false

    field :user, Types::UserType, null: false
  end
end

