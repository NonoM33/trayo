class BotPurchase < ApplicationRecord
  belongs_to :user
  belongs_to :trading_bot

  validates :price_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: "active") }
  scope :running, -> { where(is_running: true) }
  scope :stopped, -> { where(is_running: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create :initialize_tracking

  def start!
    update(
      is_running: true,
      started_at: Time.current,
      stopped_at: nil
    )
  end

  def stop!
    update(
      is_running: false,
      stopped_at: Time.current
    )
  end

  def toggle_status!
    if is_running?
      stop!
    else
      start!
    end
  end

  def status_badge
    is_running? ? '🟢 Actif' : '🔴 Inactif'
  end

  def status_color
    is_running? ? '#4CAF50' : '#F44336'
  end

  def update_performance(profit, drawdown = 0)
    self.total_profit = (total_profit || 0) + profit
    self.trades_count = (trades_count || 0) + 1
    self.current_drawdown = drawdown
    self.max_drawdown_recorded = drawdown if drawdown > (max_drawdown_recorded || 0)
    save
  end

  def roi_percentage
    return 0 if price_paid.zero?
    ((total_profit / price_paid) * 100).round(2)
  end

  def days_active
    return 0 unless started_at
    end_time = stopped_at || Time.current
    ((end_time - started_at) / 1.day).round
  end

  def average_daily_profit
    return 0 if days_active.zero?
    (total_profit / days_active).round(2)
  end

  def is_profitable?
    total_profit > 0
  end

  def drawdown_percentage
    return 0 if trading_bot.max_drawdown_limit.zero?
    ((current_drawdown / trading_bot.max_drawdown_limit) * 100).round(2)
  end

  def within_drawdown_limit?
    return true if trading_bot.max_drawdown_limit.zero?
    current_drawdown <= trading_bot.max_drawdown_limit
  end

  private

  def initialize_tracking
    update_columns(
      is_running: false,
      current_drawdown: 0,
      max_drawdown_recorded: 0,
      total_profit: 0,
      trades_count: 0
    )
  end
end

