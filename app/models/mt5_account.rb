class Mt5Account < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :destroy

  validates :mt5_id, presence: true, uniqueness: true
  validates :account_name, presence: true
  validates :balance, presence: true, numericality: true

  def update_from_mt5_data(data)
    update!(
      account_name: data[:account_name],
      balance: data[:balance],
      last_sync_at: Time.current
    )
  end

  def recent_trades(limit = 20)
    trades.order(close_time: :desc).limit(limit)
  end

  def trades_last_24h
    trades.where("close_time >= ?", 24.hours.ago).order(close_time: :desc)
  end

  def calculate_projection(days = 30)
    recent_trades = trades.where("close_time >= ?", 30.days.ago)
    
    return { projected_balance: balance, daily_average: 0, confidence: "low" } if recent_trades.empty?

    total_profit = recent_trades.sum(:profit)
    trading_days = recent_trades.select(:close_time).distinct.count
    
    return { projected_balance: balance, daily_average: 0, confidence: "low" } if trading_days.zero?

    daily_average = total_profit / trading_days
    projected_profit = daily_average * days
    projected_balance = balance + projected_profit

    confidence = if trading_days >= 20
      "high"
    elsif trading_days >= 10
      "medium"
    else
      "low"
    end

    {
      projected_balance: projected_balance.round(2),
      daily_average: daily_average.round(2),
      projected_profit: projected_profit.round(2),
      confidence: confidence,
      based_on_days: trading_days
    }
  end
end

