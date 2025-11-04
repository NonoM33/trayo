module Subscriptions
  class BaseSubscription < GraphQL::Schema::Subscription
    object_class Types::BaseObject
    field_class Types::BaseField
  end
end

