module Api
  module V2
    class BonusDepositsController < BaseController
      before_action :set_bonus_deposit, only: [:show]

      def index
        bonus_deposits = current_user.bonus_deposits
        bonus_deposits = apply_filters(bonus_deposits, allowed_filters: {
          status: {},
          amount: { gt: true, lt: true, gte: true, lte: true },
          bonus_percentage: { gt: true, lt: true, gte: true, lte: true }
        })

        if params[:start_date].present?
          bonus_deposits = bonus_deposits.where("created_at >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          bonus_deposits = bonus_deposits.where("created_at <= ?", Time.parse(params[:end_date]))
        end

        paginated = paginate_with_cursor(bonus_deposits, cursor_field: :created_at)

        render_success({
          data: paginated[:data].map { |bd| bonus_deposit_serializer(bd) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ bonus_deposit: bonus_deposit_serializer(@bonus_deposit) })
      end

      def create
        bonus_period = BonusPeriod.current.first
        bonus_percentage = bonus_period ? bonus_period.bonus_percentage : 0

        bonus_deposit = current_user.bonus_deposits.build(
          amount: bonus_deposit_params[:amount],
          bonus_percentage: bonus_percentage,
          status: 'pending'
        )

        if bonus_deposit.save
          render_success({ bonus_deposit: bonus_deposit_serializer(bonus_deposit) }, status: :created)
        else
          render_error(bonus_deposit.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      private

      def set_bonus_deposit
        @bonus_deposit = current_user.bonus_deposits.find_by(id: params[:id])
        render_error("Bonus deposit not found", status: :not_found) unless @bonus_deposit
      end

      def bonus_deposit_params
        params.require(:bonus_deposit).permit(:amount)
      end

      def bonus_deposit_serializer(bonus_deposit)
        {
          id: bonus_deposit.id,
          amount: bonus_deposit.amount,
          bonus_percentage: bonus_deposit.bonus_percentage,
          bonus_amount: bonus_deposit.bonus_amount,
          total_credit: bonus_deposit.total_credit,
          status: bonus_deposit.status,
          created_at: bonus_deposit.created_at,
          updated_at: bonus_deposit.updated_at
        }
      end
    end
  end
end

