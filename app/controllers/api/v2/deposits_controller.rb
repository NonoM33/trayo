module Api
  module V2
    class DepositsController < BaseController
      before_action :set_deposit, only: [:show]
      before_action :set_account, only: [:index, :create]

      def index
        if @account
          deposits = @account.deposits
        else
          account_ids = current_user.mt5_accounts.pluck(:id)
          deposits = Deposit.where(mt5_account_id: account_ids)
        end
        deposits = apply_filters(deposits, allowed_filters: {
          amount: { gt: true, lt: true, gte: true, lte: true }
        })

        if params[:start_date].present?
          deposits = deposits.where("deposit_date >= ?", Time.parse(params[:start_date]))
        end
        if params[:end_date].present?
          deposits = deposits.where("deposit_date <= ?", Time.parse(params[:end_date]))
        end

        paginated = paginate_with_cursor(deposits, cursor_field: :deposit_date)

        render_success({
          data: paginated[:data].map { |d| deposit_serializer(d) },
          next_cursor: paginated[:next_cursor],
          prev_cursor: paginated[:prev_cursor],
          has_more: paginated[:has_more]
        })
      end

      def show
        render_success({ deposit: deposit_serializer(@deposit) })
      end

      def create
        deposit = @account.deposits.build(deposit_params)

        if deposit.save
          render_success({ deposit: deposit_serializer(deposit) }, status: :created)
        else
          render_error(deposit.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      private

      def set_account
        if params[:account_id].present?
          @account = current_user.mt5_accounts.find_by(id: params[:account_id])
          render_error("Account not found", status: :not_found) unless @account
        end
      end

      def set_deposit
        if params[:account_id].present?
          @account = current_user.mt5_accounts.find_by(id: params[:account_id])
          @deposit = @account&.deposits&.find_by(id: params[:id])
        else
          account_ids = current_user.mt5_accounts.pluck(:id)
          @deposit = Deposit.where(id: params[:id], mt5_account_id: account_ids).first
        end
        render_error("Deposit not found", status: :not_found) unless @deposit
      end

      def deposit_params
        params.require(:deposit).permit(:amount, :deposit_date, :notes, :transaction_id)
      end

      def deposit_serializer(deposit)
        {
          id: deposit.id,
          amount: deposit.amount,
          deposit_date: deposit.deposit_date,
          notes: deposit.notes,
          transaction_id: deposit.transaction_id,
          mt5_account: {
            id: deposit.mt5_account.id,
            mt5_id: deposit.mt5_account.mt5_id,
            account_name: deposit.mt5_account.account_name
          },
          created_at: deposit.created_at,
          updated_at: deposit.updated_at
        }
      end
    end
  end
end

