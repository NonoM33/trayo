module Admin
  class BonusPeriodsController < BaseController
    before_action :require_admin
    before_action :set_bonus_period, only: [:edit, :update, :destroy, :toggle_active]

    def index
      @bonus_periods = BonusPeriod.order(start_date: :desc)
      @current_period = BonusPeriod.current.first
    end

    def new
      @bonus_period = BonusPeriod.new
    end

    def create
      @bonus_period = BonusPeriod.new(bonus_period_params)

      if @bonus_period.save
        redirect_to admin_bonus_periods_path, notice: "Bonus period created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @bonus_period.update(bonus_period_params)
        redirect_to admin_bonus_periods_path, notice: "Bonus period updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @bonus_period.destroy
      redirect_to admin_bonus_periods_path, notice: "Bonus period deleted successfully"
    end

    def toggle_active
      @bonus_period.update(active: !@bonus_period.active)
      redirect_to admin_bonus_periods_path, notice: "Bonus period #{@bonus_period.active ? 'activated' : 'deactivated'}"
    end

    private

    def set_bonus_period
      @bonus_period = BonusPeriod.find(params[:id])
    end

    def bonus_period_params
      params.require(:bonus_period).permit(:bonus_percentage, :start_date, :end_date, :name, :description, :active)
    end
  end
end

