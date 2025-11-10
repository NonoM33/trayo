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
  after_update :broadcast_status_change
  
  def associated_trades
    return Trade.none unless magic_number
    
    Trade.joins(mt5_account: :user)
         .where(users: { id: user_id })
         .where(magic_number: magic_number)
  end
  
  def sync_performance_from_trades
    trades = associated_trades
    return unless trades.any?
    
    self.total_profit = trades.sum(:profit)
    self.trades_count = trades.count
    
    current_balance = user.mt5_accounts.sum(:balance)
    peak_balance = user.mt5_accounts.maximum(:balance) || current_balance
    self.current_drawdown = [peak_balance - current_balance, 0].max
    self.max_drawdown_recorded = [max_drawdown_recorded, current_drawdown].compact.max
    
    save
  end
  
  def total_commission
    result = associated_trades.sum(:commission)
    result.nil? ? 0.0 : result.round(2)
  end
  
  def total_swap
    result = associated_trades.sum(:swap)
    result.nil? ? 0.0 : result.round(2)
  end
  
  def gross_profit_before_costs
    (total_profit.to_f + total_commission + total_swap).round(2)
  end
  
  def total_costs
    (total_commission + total_swap).round(2)
  end

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

  def calculate_current_drawdown
    trades = associated_trades.order(:close_time)
    return 0 unless trades.any?
    
    running_balance = 0
    peak_balance = 0
    max_drawdown = 0
    
    trades.each do |trade|
      running_balance += (trade.profit || 0)
      peak_balance = [peak_balance, running_balance].max
      current_drawdown = peak_balance - running_balance
      max_drawdown = [max_drawdown, current_drawdown].max
    end
    
    max_drawdown.round(2)
  end
  
  def drawdown_percentage
    return 0 if price_paid.zero?
    current_dd = calculate_current_drawdown
    ((current_dd / price_paid) * 100).round(2)
  end
  
  def get_current_drawdown
    calculate_current_drawdown
  end

  def within_drawdown_limit?
    return true if trading_bot.max_drawdown_limit.zero?
    current_drawdown <= trading_bot.max_drawdown_limit
  end
  
  def analyze_by_day_of_week
    trades = associated_trades
    return {} unless trades.any?
    
    days_map = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
    
    by_day = trades.group_by { |t| t.close_time&.wday }
    
    by_day.map do |wday, day_trades|
      {
        day_name: days_map[wday],
        wday: wday,
        total_trades: day_trades.count,
        total_profit: day_trades.sum { |t| t.profit || 0 },
        winning_trades: day_trades.count { |t| (t.profit || 0) > 0 },
        losing_trades: day_trades.count { |t| (t.profit || 0) < 0 },
        avg_profit: day_trades.any? ? (day_trades.sum { |t| t.profit || 0 } / day_trades.count).round(2) : 0,
        total_commission: day_trades.sum { |t| t.commission || 0 },
        total_swap: day_trades.sum { |t| t.swap || 0 }
      }
    end
  end
  
  def analyze_by_hour
    trades = associated_trades
    return {} unless trades.any?
    
    by_hour = trades.group_by { |t| t.close_time&.hour }
    
    by_hour.map do |hour, hour_trades|
      {
        hour: hour,
        total_trades: hour_trades.count,
        total_profit: hour_trades.sum { |t| t.profit || 0 },
        winning_trades: hour_trades.count { |t| (t.profit || 0) > 0 },
        losing_trades: hour_trades.count { |t| (t.profit || 0) < 0 },
        avg_profit: hour_trades.any? ? (hour_trades.sum { |t| t.profit || 0 } / hour_trades.count).round(2) : 0
      }
    end.sort_by { |h| h[:hour] }
  end
  
  def analyze_trade_duration
    trades = associated_trades.where.not(open_time: nil, close_time: nil)
    return { avg_duration_minutes: 0, avg_duration_hours: 0, min_duration_minutes: 0, max_duration_minutes: 0 } unless trades.any?
    
    durations = trades.map do |t|
      if t.close_time && t.open_time && t.close_time != t.open_time
        ((t.close_time - t.open_time) / 60)
      end
    end.compact
    
    return { avg_duration_minutes: 0, avg_duration_hours: 0, min_duration_minutes: 0, max_duration_minutes: 0 } if durations.empty?
    
    avg_minutes = (durations.sum / durations.count).round(1)
    
    {
      avg_duration_minutes: avg_minutes,
      avg_duration_hours: (avg_minutes / 60).round(2),
      min_duration_minutes: durations.min.round(1),
      max_duration_minutes: durations.max.round(1)
    }
  end
  
  def get_best_performing_day
    days = analyze_by_day_of_week
    return nil if days.empty?
    days.max_by { |d| d[:total_profit] }
  end
  
  def get_most_active_day
    days = analyze_by_day_of_week
    return nil if days.empty?
    days.max_by { |d| d[:total_trades] }
  end
  
  def get_riskiest_day
    days = analyze_by_day_of_week
    return nil if days.empty?
    days.max_by { |d| d[:losing_trades] }
  end
  
  def get_best_performing_hour
    hours = analyze_by_hour
    return nil if hours.empty?
    hours.max_by { |h| h[:total_profit] }
  end
  
  def get_most_active_hour
    hours = analyze_by_hour
    return nil if hours.empty?
    hours.max_by { |h| h[:total_trades] }
  end

  private

  def initialize_tracking
    self.magic_number = generate_magic_number if magic_number.nil?
    
    update_columns(
      magic_number: magic_number,
      is_running: false,
      current_drawdown: 0,
      max_drawdown_recorded: 0,
      total_profit: 0,
      trades_count: 0
    )
  end
  
  def generate_magic_number
    base = trading_bot.magic_number_prefix || (trading_bot.id * 1000)
    base + user_id
  end

  def broadcast_status_change
    return unless is_running_changed? || status_changed? || saved_change_to_is_running? || saved_change_to_status?

    BotChannel.broadcast_status_change(self)
    TrayoSchema.subscriptions.trigger(:bot_status_changed, {}, self)
  rescue => e
    Rails.logger.error "Failed to broadcast bot status change: #{e.message}"
  end
end

