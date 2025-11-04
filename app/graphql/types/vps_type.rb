module Types
  class VpsType < Types::BaseObject
    description "VPS type"

    field :id, ID, null: false
    field :name, String, null: false
    field :server_location, String, null: true
    field :status, String, null: false
    field :monthly_price, Float, null: true
    field :renewal_date, Types::DateTimeType, null: true
    field :ip_address, String, null: true
    field :username, String, null: true
    field :password, String, null: true
    field :ordered_at, Types::DateTimeType, null: true
    field :configured_at, Types::DateTimeType, null: true
    field :ready_at, Types::DateTimeType, null: true
    field :activated_at, Types::DateTimeType, null: true
    field :created_at, Types::DateTimeType, null: false
    field :updated_at, Types::DateTimeType, null: false

    field :user, Types::UserType, null: false

    def username
      return nil unless context[:current_user]&.is_admin?
      object.username
    end

    def password
      return nil unless context[:current_user]&.is_admin?
      object.password
    end
  end
end

