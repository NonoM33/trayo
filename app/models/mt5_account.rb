class Mt5Account < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :withdrawals, dependent: :destroy
  has_many :deposits, dependent: :destroy

  validates :mt5_id, presence: true, uniqueness: true
  validates :account_name, presence: true
  validates :balance, presence: true, numericality: true

  after_save :clear_user_cache
  after_save :recalculate_initial_balance_if_needed
  after_save :broadcast_balance_updated

  def update_from_mt5_data(data)
    account_name = data[:account_name].present? ? data[:account_name] : self.account_name
    balance = data[:balance].present? ? data[:balance].to_f : self.balance
    
    update!(
      account_name: account_name,
      balance: balance,
      last_sync_at: Time.current
    )
  end

  def total_profits
    trades.where("profit > ?", 0).sum(:profit)
  end

  def net_gains
    initial = if calculated_initial_balance.present?
      calculated_initial_balance
    elsif initial_balance.present? && initial_balance > 0
      initial_balance
    else
      0
    end
    
    (balance - initial + (total_withdrawals || 0)).round(2)
  end

  def real_gains
    initial = if calculated_initial_balance.present?
      calculated_initial_balance
    elsif initial_balance.present? && initial_balance > 0
      initial_balance
    else
      0
    end
    
    (balance - initial).round(2)
  end

  def calculate_initial_balance_from_history
    # Calcul automatique du capital initial basé sur l'historique complet
    # La balance initiale = somme de tous les dépôts
    total_deposits_amount = deposits.sum(:amount) || 0
    
    # Utiliser update_column pour éviter les callbacks
    update_columns(
      calculated_initial_balance: total_deposits_amount.round(2),
      auto_calculated_initial_balance: true,
      total_deposits: total_deposits_amount,
      total_withdrawals: withdrawals.sum(:amount) || 0
    )
    
    total_deposits_amount.round(2)
  end

  def adjusted_watermark
    # Le watermark ne doit jamais être ajusté à la baisse
    # Les retraits n'affectent pas le watermark pour le calcul des commissions
    high_watermark
  end

  def commissionable_gains
    return 0 if balance.nil? || high_watermark.nil?
    gains = balance - high_watermark
    gains > 0 ? gains.round(2) : 0
  end

  def recalculate_watermark!
    if balance > high_watermark
      update!(high_watermark: balance)
    end
  end

  def set_watermark_to_current_balance!
    update!(high_watermark: balance)
  end

  def clear_user_cache
    user.reload if user.present?
  rescue ActiveRecord::RecordNotFound
    # Ignore si l'utilisateur n'existe plus
  end

  def recalculate_initial_balance_if_needed
    if auto_calculated_initial_balance
      calculate_initial_balance_from_history
    end
  end

  # Méthode pour forcer le recalcul de la balance initiale
  def force_recalculate_initial_balance!
    calculate_initial_balance_from_history
    save!
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

  def account_name_with_user
    name = "#{account_name} (#{user.first_name} #{user.last_name})"
    name.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    account_name.to_s
  end

  def apply_trade_defender_penalty(profit_amount)
    new_watermark = high_watermark - profit_amount.abs
    update(high_watermark: new_watermark)
  end

  def unauthorized_manual_trades_total
    trades.unauthorized_manual.sum { |t| t.profit.abs }
  end

  def recalculate_watermark_with_penalties
    unauthorized_trades = trades.unauthorized_manual
    total_penalty = unauthorized_trades.sum { |t| t.profit.abs }
    adjusted_watermark = balance - total_penalty
    update(high_watermark: adjusted_watermark)
  end

  def broadcast_balance_updated
    return unless balance_changed? || saved_change_to_balance?

    AccountChannel.broadcast_update(self)
    TrayoSchema.subscriptions.trigger(:account_balance_updated, {}, self)
  rescue PG::ConnectionBad, PG::Error, ActiveRecord::ConnectionNotEstablished => e
    if e.message.include?("socket") || e.message.include?("connection")
      Rails.logger.debug "ActionCable broadcast skipped (connection issue): #{e.class}"
    else
      Rails.logger.error "Failed to broadcast balance updated: #{e.message}"
    end
  rescue => e
    Rails.logger.error "Failed to broadcast balance updated: #{e.message}"
  end
end

