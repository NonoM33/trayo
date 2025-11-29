class Admin::FinanceController < Admin::BaseController
  before_action :require_admin

  def index
    @tab = params[:tab] || 'payments'
    
    case @tab
    when 'payments'
      @payments = Payment.includes(:user).order(payment_date: :desc).limit(100)
    when 'credits'
      @credits = Credit.includes(:user).order(created_at: :desc).limit(100)
    when 'bonus'
      @bonus_deposits = BonusDeposit.includes(:user).order(created_at: :desc).limit(100)
      @bonus_periods = BonusPeriod.order(start_date: :desc)
      @current_period = BonusPeriod.current.first
    when 'movements'
      @withdrawals = Withdrawal.includes(mt5_account: :user).order(withdrawal_date: :desc).limit(100)
      @deposits = Deposit.includes(mt5_account: :user).order(deposit_date: :desc).limit(100)
    end
    
    load_stats
  end

  private

  def load_stats
    @stats = {
      total_payments: Payment.count,
      pending_payments: Payment.where(status: 'pending').count,
      total_credits: Credit.sum(:amount),
      total_bonus: BonusDeposit.where(status: 'validated').sum(:amount),
      total_withdrawals: Withdrawal.sum(:amount),
      total_deposits: Deposit.sum(:amount)
    }
  end
end

