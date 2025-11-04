module Types
  class DateTimeType < Types::BaseScalar
    description "DateTime scalar type"

    def self.coerce_input(value, _context)
      Time.zone.parse(value)
    rescue ArgumentError
      raise GraphQL::CoercionError, "#{value.inspect} is not a valid DateTime"
    end

    def self.coerce_result(value, _context)
      value.utc.iso8601
    end
  end
end

