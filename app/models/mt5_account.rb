class Mt5Account < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :withdrawals, dependent: :destroy
  has_many :deposits, dependent: :destroy

  validates :mt5_id, presence: true, uniqueness: true
  validates :account_name, presence: true
  validates :balance, presence: true, numericality: true

  after_update :check_and_update_watermark
  after_save :clear_user_cache

  def update_from_mt5_data(data)
    # Valider les données avant la mise à jour
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
    if auto_calculated_initial_balance && calculated_initial_balance.present?
      (balance - calculated_initial_balance + (total_withdrawals || 0) - (total_deposits || 0)).round(2)
    else
      (balance - initial_balance + (total_withdrawals || 0)).round(2)
    end
  end

  def real_gains
    # Gains réels sans tenir compte des retraits (pour affichage)
    if auto_calculated_initial_balance && calculated_initial_balance.present?
      (balance - calculated_initial_balance).round(2)
    else
      (balance - initial_balance).round(2)
    end
  end

  def calculate_initial_balance_from_history
    # Calcul automatique du capital initial basé sur l'historique complet
    total_profits = trades.sum(:profit) || 0
    total_withdrawals_amount = withdrawals.sum(:amount) || 0
    total_deposits_amount = deposits.sum(:amount) || 0
    
    calculated_initial = balance - total_profits + total_withdrawals_amount - total_deposits_amount
    
    # Utiliser update_column pour éviter les callbacks
    update_columns(
      calculated_initial_balance: calculated_initial.round(2),
      auto_calculated_initial_balance: true,
      total_deposits: total_deposits_amount,
      total_withdrawals: total_withdrawals_amount
    )
    
    calculated_initial.round(2)
  end

  def adjusted_watermark
    high_watermark - (total_withdrawals || 0)
  end

  def commissionable_gains
    # Les gains commissionnables sont basés sur le watermark ajusté (sans les retraits)
    # mais les gains nets incluent les retraits pour le calcul total
    gains = balance - adjusted_watermark
    gains > 0 ? gains.round(2) : 0
  end

  def recalculate_watermark!
    if balance > high_watermark
      update!(high_watermark: balance)
    end
  end

  def check_and_update_watermark
    recalculate_watermark! if saved_change_to_balance?
  end

  def clear_user_cache
    user.reload if user.present?
  rescue ActiveRecord::RecordNotFound
    # Ignore si l'utilisateur n'existe plus
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
    "#{account_name} (#{user.first_name} #{user.last_name})"
  end
end

