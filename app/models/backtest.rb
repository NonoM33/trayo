class Backtest < ApplicationRecord
  belongs_to :trading_bot
  
  validates :total_trades, :winning_trades, :losing_trades, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_profit, :max_drawdown, :win_rate, numericality: true, allow_nil: true
  validates :start_date, :end_date, presence: true
  
  scope :active, -> { where(is_active: true) }
  scope :latest, -> { order(created_at: :desc) }
  
  def duration_days
    return 0 unless start_date && end_date
    ((end_date - start_date) / 1.day).to_i
  end
  
  def duration_years
    (duration_days / 365.0).round(2)
  end
  
  def calculate_projections
    return unless start_date && end_date
    
    days = duration_days
    return if days <= 0
    
    total_days_in_period = days
    avg_daily_profit = total_profit / total_days_in_period
    
    self.projection_monthly_min = (avg_daily_profit * 22 * 0.8).round(2)
    self.projection_monthly_max = (avg_daily_profit * 22 * 1.2).round(2)
    self.projection_yearly = (avg_daily_profit * 252).round(2)
  end
  
  def activate!
    # Désactiver les autres backtests du même bot
    trading_bot.backtests.where.not(id: id).update_all(is_active: false)
    # Activer celui-ci
    update!(is_active: true)
  end
end

