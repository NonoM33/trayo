module Types
  class PageInfoType < Types::BaseObject
    description "Information about pagination"

    field :has_next_page, Boolean, null: false
    field :has_previous_page, Boolean, null: false
    field :start_cursor, String, null: true
    field :end_cursor, String, null: true
  end
end

