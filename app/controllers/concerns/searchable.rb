module Searchable
  extend ActiveSupport::Concern

  included do
    protected

    def apply_search(scope, search_fields: [])
      return scope unless params[:search].present?

      search_term = params[:search]
      search_fields_param = params[:search_fields]&.split(',') || search_fields

      conditions = search_fields_param.map do |field|
        "#{field} ILIKE ?"
      end.join(' OR ')

      values = search_fields_param.map { |_| "%#{search_term}%" }

      scope.where(conditions, *values)
    end
  end
end

