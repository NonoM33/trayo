module Api
  module V2
    class PaymentsController < BaseController
      before_action :set_payment, only: [:show]

      def index
        payments = current_user.payments
        payments = apply_filters(payments, allowed_filters: {
          status: {},
          amount: { gt: true, lt: true, gte: true, lte: true }
        })

        if params[:start_date].present?
          payments = payments.where("payment_date >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          payments = payments.where("payment_date <= ?", Time.parse(params[:end_date]))
        end

        paginated = paginate_with_cursor(payments, cursor_field: :payment_date)

        render_success({
          data: paginated[:data].map { |p| payment_serializer(p) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ payment: payment_serializer(@payment) })
      end

      def create
        payment = current_user.payments.build(payment_params)

        if payment.save
          render_success({ payment: payment_serializer(payment) }, status: :created)
        else
          render_error(payment.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      def balance_due
        render_success({
          balance_due: current_user.balance_due,
          total_commission_due: current_user.total_commission_due,
          total_credits: current_user.total_credits
        })
      end

      private

      def set_payment
        @payment = current_user.payments.find_by(id: params[:id])
        render_error("Payment not found", status: :not_found) unless @payment
      end

      def payment_params
        params.require(:payment).permit(:amount, :description, :payment_method, :payment_date)
      end

      def payment_serializer(payment)
        {
          id: payment.id,
          amount: payment.amount,
          status: payment.status,
          payment_date: payment.payment_date,
          description: payment.description,
          payment_method: payment.payment_method,
          created_at: payment.created_at,
          updated_at: payment.updated_at
        }
      end
    end
  end
end

