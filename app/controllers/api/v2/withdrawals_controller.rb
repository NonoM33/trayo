module Api
  module V2
    class WithdrawalsController < BaseController
      before_action :set_withdrawal, only: [:show]
      before_action :set_account, only: [:index, :create]

      def index
        if @account
          withdrawals = @account.withdrawals
        else
          account_ids = current_user.mt5_accounts.pluck(:id)
          withdrawals = Withdrawal.where(mt5_account_id: account_ids)
        end
        withdrawals = apply_filters(withdrawals, allowed_filters: {
          amount: { gt: true, lt: true, gte: true, lte: true }
        })

        if params[:start_date].present?
          withdrawals = withdrawals.where("withdrawal_date >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          withdrawals = withdrawals.where("withdrawal_date <= ?", Time.parse(params[:end_date]))
        end

        paginated = paginate_with_cursor(withdrawals, cursor_field: :withdrawal_date)

        render_success({
          data: paginated[:data].map { |w| withdrawal_serializer(w) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ withdrawal: withdrawal_serializer(@withdrawal) })
      end

      def create
        withdrawal = @account.withdrawals.build(withdrawal_params)

        if withdrawal.save
          render_success({ withdrawal: withdrawal_serializer(withdrawal) }, status: :created)
        else
          render_error(withdrawal.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      private

      def set_account
        if params[:account_id].present?
          @account = current_user.mt5_accounts.find_by(id: params[:account_id])
          render_error("Account not found", status: :not_found) unless @account
        end
      end

      def set_withdrawal
        if params[:account_id].present?
          @account = current_user.mt5_accounts.find_by(id: params[:account_id])
          @withdrawal = @account&.withdrawals&.find_by(id: params[:id])
        else
          account_ids = current_user.mt5_accounts.pluck(:id)
          @withdrawal = Withdrawal.where(id: params[:id], mt5_account_id: account_ids).first
        end
        render_error("Withdrawal not found", status: :not_found) unless @withdrawal
      end

      def withdrawal_params
        params.require(:withdrawal).permit(:amount, :withdrawal_date, :notes)
      end

      def withdrawal_serializer(withdrawal)
        {
          id: withdrawal.id,
          amount: withdrawal.amount,
          withdrawal_date: withdrawal.withdrawal_date,
          notes: withdrawal.notes,
          mt5_account: {
            id: withdrawal.mt5_account.id,
            mt5_id: withdrawal.mt5_account.mt5_id,
            account_name: withdrawal.mt5_account.account_name
          },
          created_at: withdrawal.created_at,
          updated_at: withdrawal.updated_at
        }
      end
    end
  end
end

