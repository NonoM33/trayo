module Admin
  class BonusDepositsController < BaseController
    def index
      if current_user.is_admin?
        @bonus_deposits = BonusDeposit.includes(:user).order(created_at: :desc)
      else
        @bonus_deposits = current_user.bonus_deposits.order(created_at: :desc)
        @current_bonus_rate = calculate_current_bonus_rate
        @bonus_periods = BonusPeriod.active.order(start_date: :desc)
      end
    end

    def new
      @bonus_deposit = current_user.bonus_deposits.build
      @current_bonus_rate = calculate_current_bonus_rate
      @current_period = BonusPeriod.current.first
    end

    def create
      @bonus_deposit = current_user.bonus_deposits.build(bonus_params)
      @bonus_deposit.bonus_percentage = calculate_current_bonus_rate

      if @bonus_deposit.save
        redirect_to admin_bonus_deposits_path, notice: "Bonus deposit request submitted successfully"
      else
        @current_bonus_rate = calculate_current_bonus_rate
        render :new, status: :unprocessable_entity
      end
    end

    def validate_deposit
      require_admin
      @bonus_deposit = BonusDeposit.find(params[:id])
      @bonus_deposit.validate!
      redirect_to admin_bonus_deposits_path, notice: "Bonus deposit validated and credit applied"
    end

    def reject_deposit
      require_admin
      @bonus_deposit = BonusDeposit.find(params[:id])
      @bonus_deposit.reject!
      redirect_to admin_bonus_deposits_path, notice: "Bonus deposit rejected"
    end

    private

    def bonus_params
      params.require(:bonus_deposit).permit(:amount, :notes)
    end

    def calculate_current_bonus_rate
      BonusPeriod.current_bonus_percentage
    end
  end
end

