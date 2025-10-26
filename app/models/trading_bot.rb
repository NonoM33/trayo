class TradingBot < ApplicationRecord
  has_many :bot_purchases, dependent: :destroy
  has_many :users, through: :bot_purchases

  RISK_LEVELS = %w[low medium high].freeze

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }
  validates :risk_level, inclusion: { in: RISK_LEVELS }, allow_nil: true
  validates :magic_number_prefix, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :active, -> { where(status: "active") }
  scope :available, -> { where(is_active: true) }
  scope :featured, -> { where("features @> ?", { featured: true }.to_json) }
  scope :by_risk, ->(level) { where(risk_level: level) }
  scope :with_magic_number_prefix, ->(magic) { where(magic_number_prefix: magic) }

  def risk_badge_color
    case risk_level
    when 'low' then '#4CAF50'
    when 'medium' then '#FF9800'
    when 'high' then '#F44336'
    else '#999'
    end
  end

  def risk_label
    case risk_level
    when 'low' then 'FAIBLE'
    when 'medium' then 'MODÉRÉ'
    when 'high' then 'ÉLEVÉ'
    else 'N/A'
    end
  end

  def projected_monthly_average
    return 0 if projection_monthly_min.nil? || projection_monthly_max.nil?
    ((projection_monthly_min + projection_monthly_max) / 2).round(2)
  end

  def projected_profit_for_capital(capital, months = 12)
    return 0 if projected_monthly_average.zero?
    (projected_monthly_average * months).round(2)
  end

  def roi_percentage(capital)
    return 0 if capital.zero? || projection_yearly.zero?
    ((projection_yearly / capital) * 100).round(2)
  end

  def features_list
    features.is_a?(Array) ? features : []
  end

  def active_users_count
    bot_purchases.where(status: 'active').count
  end

  def average_performance
    purchases = bot_purchases.where.not(total_profit: nil)
    return 0 if purchases.empty?
    (purchases.sum(:total_profit) / purchases.count).round(2)
  end

  def formatted_price
    "#{price.round(0)} €"
  end

  def marketing_tagline
    "Générez jusqu'à #{projection_monthly_max.round(0)} € par mois"
  end

  def trades_for_magic_number_prefix(magic_number_prefix)
    Trade.joins(mt5_account: :user)
         .where(users: { id: users.ids })
         .where("magic_number::text LIKE ?", "#{magic_number_prefix}%")
  end

  def calculate_performance_for_magic_number_prefix(magic_number_prefix)
    trades = trades_for_magic_number_prefix(magic_number_prefix)
    return { profit: 0, trades_count: 0, drawdown: 0 } if trades.empty?

    total_profit = trades.sum(:profit)
    trades_count = trades.count
    
    # Calculer le drawdown
    running_balance = 0
    peak_balance = 0
    max_drawdown = 0
    
    trades.order(:close_time).each do |trade|
      running_balance += trade.profit
      peak_balance = [peak_balance, running_balance].max
      current_drawdown = peak_balance - running_balance
      max_drawdown = [max_drawdown, current_drawdown].max
    end

    {
      profit: total_profit.round(2),
      trades_count: trades_count,
      drawdown: max_drawdown.round(2),
      win_rate: calculate_win_rate(trades),
      avg_profit_per_trade: (total_profit / trades_count).round(2)
    }
  end

  def calculate_win_rate(trades)
    return 0 if trades.empty?
    winning_trades = trades.where("profit > 0").count
    (winning_trades.to_f / trades.count * 100).round(2)
  end

  def sync_performance_from_trades
    return unless magic_number_prefix.present?
    
    performance = calculate_performance_for_magic_number_prefix(magic_number_prefix)
    
    # Mettre à jour tous les bot_purchases de ce bot
    bot_purchases.each do |purchase|
      purchase.update!(
        total_profit: performance[:profit],
        trades_count: performance[:trades_count],
        max_drawdown_recorded: performance[:drawdown]
      )
    end
  end
end

