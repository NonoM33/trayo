module Filterable
  extend ActiveSupport::Concern

  included do
    protected

    def apply_filters(scope, allowed_filters: {})
      return scope unless params[:filters].present?

      filters = params[:filters].permit(*allowed_filters.keys)

      filters.each do |key, value|
        filter_config = allowed_filters[key.to_sym]
        next unless filter_config

        operator = value.is_a?(Hash) ? value.keys.first : :eq
        filter_value = value.is_a?(Hash) ? value.values.first : value

        case operator.to_s
        when 'eq'
          scope = scope.where(key => filter_value)
        when 'neq'
          scope = scope.where.not(key => filter_value)
        when 'gt'
          scope = scope.where("#{key} > ?", filter_value)
        when 'gte'
          scope = scope.where("#{key} >= ?", filter_value)
        when 'lt'
          scope = scope.where("#{key} < ?", filter_value)
        when 'lte'
          scope = scope.where("#{key} <= ?", filter_value)
        when 'in'
          scope = scope.where(key => filter_value.is_a?(Array) ? filter_value : [filter_value])
        when 'not_in'
          scope = scope.where.not(key => filter_value.is_a?(Array) ? filter_value : [filter_value])
        when 'like'
          scope = scope.where("#{key} ILIKE ?", "%#{filter_value}%")
        when 'between'
          if filter_value.is_a?(Array) && filter_value.length == 2
            scope = scope.where("#{key} BETWEEN ? AND ?", filter_value[0], filter_value[1])
          end
        end
      end

      scope
    end
  end
end

