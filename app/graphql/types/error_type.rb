module Types
  class ErrorType < Types::BaseObject
    description "Error information"

    field :field, String, null: true
    field :message, String, null: false
  end
end

