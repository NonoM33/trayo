module CursorPagination
  extend ActiveSupport::Concern

  included do
    protected

    def paginate_with_cursor(scope, cursor_field: :id, limit: 20)
      limit = [limit.to_i, 100].min.clamp(1, 100)
      cursor = params[:cursor]
      direction = params[:direction] || 'next'

      if cursor.present?
        if direction == 'next'
          scope = scope.where("#{cursor_field} > ?", cursor)
        else
          scope = scope.where("#{cursor_field} < ?", cursor)
        end
      end

      results = scope.order(cursor_field => direction == 'next' ? :asc : :desc).limit(limit + 1)
      has_more = results.count > limit
      results = results.first(limit)

      next_cursor = results.last&.public_send(cursor_field) if has_more && direction == 'next'
      prev_cursor = results.first&.public_send(cursor_field) if direction == 'prev' || (has_more && direction == 'next')

      {
        data: results.reverse,
        next_cursor: next_cursor,
        prev_cursor: prev_cursor,
        has_more: has_more
      }
    end
  end
end

