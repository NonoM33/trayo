class TradingBot < ApplicationRecord
  has_many :bot_purchases, dependent: :destroy
  has_many :users, through: :bot_purchases
  has_many :backtests, dependent: :destroy
  has_many :bot_updates, dependent: :destroy

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
  
  def active_backtest
    backtests.active.first
  end
  
  def real_marketing_tagline
    # Toujours utiliser calculate_real_projections pour avoir les valeurs adaptées au capital
    projections = calculate_real_projections
    
    if projections[:yearly] != 0 || projections[:monthly_max] != 0
      max_monthly = projections[:monthly_max]
    elsif projection_monthly_max && projection_monthly_max > 0
      max_monthly = projection_monthly_max
    else
      max_monthly = 0
    end
    
    "Générez jusqu'à #{max_monthly.round(0)} € par mois"
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
  
  def calculate_real_projections
    # Priorité 1: Utiliser le backtest actif si disponible
    if active_backtest
      # Adapter les projections au capital du bot (prix)
      # Le backtest est fait avec un capital initial (10,000€ par défaut)
      # On doit adapter pour le prix du bot (400€)
      backtest_capital = 10000.0
      bot_price = price.to_f
      
      # Calculer le ratio d'adaptation
      ratio = bot_price / backtest_capital
      
      # Adapter toutes les projections
      monthly_min = (active_backtest.projection_monthly_min || 0) * ratio
      monthly_max = (active_backtest.projection_monthly_max || 0) * ratio
      yearly = (active_backtest.projection_yearly || 0) * ratio
      drawdown = (active_backtest.max_drawdown || 0) * ratio
      
      # Le drawdown en % reste le même (c'est un pourcentage)
      drawdown_pct = 0
      if backtest_capital > 0
        # Calculer le pourcentage de drawdown du backtest
        backtest_drawdown_abs = active_backtest.max_drawdown || 0
        drawdown_pct = (backtest_drawdown_abs / backtest_capital * 100).round(1)
      end
      
      return {
        monthly_min: monthly_min.round(2),
        monthly_max: monthly_max.round(2),
        yearly: yearly.round(2),
        daily_return: 0,
        drawdown: drawdown_pct
      }
    end
    
    # Priorité 2: Calculer depuis les trades réels
    return { monthly_min: 0, monthly_max: 0, yearly: 0, daily_return: 0, drawdown: 0 } unless magic_number_prefix.present?
    
    trades = Trade.where("magic_number >= ? AND magic_number < ?", magic_number_prefix, magic_number_prefix + 1000)
                  .where.not(close_time: nil)
    
    return { monthly_min: 0, monthly_max: 0, yearly: 0, daily_return: 0, drawdown: 0 } if trades.empty?
    
    total_profit = trades.sum(:profit).to_f
    oldest_trade = trades.minimum(:close_time)
    newest_trade = trades.maximum(:close_time)
    
    return { monthly_min: 0, monthly_max: 0, yearly: 0, daily_return: 0, drawdown: 0 } if oldest_trade.nil? || newest_trade.nil?
    
    days_diff = ((newest_trade - oldest_trade) / 1.day).to_f
    return { monthly_min: 0, monthly_max: 0, yearly: 0, daily_return: 0, drawdown: 0 } if days_diff <= 0
    
    avg_daily_profit = total_profit / days_diff
    yearly = (avg_daily_profit * 252).round(2)
    monthly_min = (avg_daily_profit * 22 * 0.8).round(2)
    monthly_max = (avg_daily_profit * 22 * 1.2).round(2)
    
    # Pour le ROI, utiliser le prix du bot
    avg_price = price
    daily_return = avg_price > 0 ? ((yearly / avg_price) / 252 * 100).round(3) : 0
    
    # Calculer le drawdown à partir des trades
    running_balance = 0
    peak_balance = 0
    max_drawdown = 0
    
    trades.order(:close_time).each do |trade|
      running_balance += (trade.profit || 0)
      peak_balance = [peak_balance, running_balance].max
      current_drawdown = peak_balance - running_balance
      max_drawdown = [max_drawdown, current_drawdown].max
    end
    
    avg_drawdown_pct = avg_price > 0 ? ((max_drawdown / avg_price) * 100).round(1) : 0
    
    { 
      monthly_min: monthly_min,
      monthly_max: monthly_max,
      yearly: yearly,
      daily_return: daily_return,
      drawdown: avg_drawdown_pct
    }
  end
  
  def calculate_global_win_rate
    if active_backtest&.win_rate
      return active_backtest.win_rate
    end
    
    return 0 unless magic_number_prefix.present?
    
    trades = Trade.where("magic_number >= ? AND magic_number < ?", magic_number_prefix, magic_number_prefix + 1000)
                  .where.not(close_time: nil)
    
    return 0 if trades.empty?
    
    winning_trades = trades.where("profit > 0").count
    (winning_trades.to_f / trades.count * 100).round(2)
  end

  def latest_update
    bot_updates.released.recent.first
  end

  def has_pending_updates_for?(user)
    return false unless user
    
    bot_purchase = bot_purchases.find_by(user: user)
    return false unless bot_purchase
    
    current_version > (bot_purchase.version_purchased || "0.0.0")
  end

  def pending_updates_for(user)
    return BotUpdate.none unless user
    
    bot_purchase = bot_purchases.find_by(user: user)
    return BotUpdate.none unless bot_purchase
    
    bot_updates.released.where("version > ?", bot_purchase.version_purchased || "0.0.0").recent
  end

  def users_needing_update
    bot_purchases.where("version_purchased < ?", current_version || "1.0.0")
                 .where(has_update_pass: false)
                 .includes(:user)
                 .map(&:user)
  end

  def users_with_update_pass
    bot_purchases.where(has_update_pass: true)
                 .where("update_pass_expires_at > ?", Time.current)
                 .includes(:user)
                 .map(&:user)
  end

  def update_revenue
    BotUpdatePurchase.joins(:bot_update)
                     .where(bot_updates: { trading_bot_id: id })
                     .completed
                     .sum(:price_paid)
  end
end

