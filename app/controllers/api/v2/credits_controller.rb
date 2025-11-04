module Api
  module V2
    class CreditsController < BaseController
      before_action :set_credit, only: [:show]

      def index
        credits = current_user.credits
        paginated = paginate_with_cursor(credits, cursor_field: :created_at)

        render_success({
          data: paginated[:data].map { |c| credit_serializer(c) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ credit: credit_serializer(@credit) })
      end

      private

      def set_credit
        @credit = current_user.credits.find_by(id: params[:id])
        render_error("Credit not found", status: :not_found) unless @credit
      end

      def credit_serializer(credit)
        {
          id: credit.id,
          amount: credit.amount,
          reason: credit.reason,
          created_at: credit.created_at
        }
      end
    end
  end
end

