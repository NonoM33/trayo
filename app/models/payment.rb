class Payment < ApplicationRecord
  belongs_to :user

  PAYMENT_METHODS = %w[bank_transfer cash paypal credit_card check other].freeze

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending validated rejected] }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS, allow_blank: true }

  scope :validated, -> { where(status: "validated") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(payment_date: :desc) }

  def validate!
    transaction do
      capture_watermark_snapshot
      capture_trade_defender_penalties
      update_watermarks_on_validation
      update!(status: "validated")
    end
  end

  def reject!
    update!(status: "rejected")
  end

  def payment_method_label
    return "N/A" if payment_method.blank?
    {
      "bank_transfer" => "Bank Transfer",
      "cash" => "Cash",
      "paypal" => "PayPal",
      "credit_card" => "Credit Card",
      "check" => "Check",
      "other" => "Other"
    }[payment_method] || payment_method
  end

  def watermark_data
    return {} if watermark_snapshot.blank?
    JSON.parse(watermark_snapshot)
  rescue JSON::ParserError
    {}
  end
  
  def trade_defender_penalties_data
    return {} if trade_defender_penalties_snapshot.blank?
    JSON.parse(trade_defender_penalties_snapshot)
  rescue JSON::ParserError
    {}
  end

  private

  def capture_watermark_snapshot
    snapshot = {}
    
    user.mt5_accounts.each do |account|
      snapshot[account.mt5_id] = {
        account_name: account.account_name,
        balance: account.balance,
        watermark: account.high_watermark,
        commissionable: account.commissionable_gains
      }
    end
    
    self.watermark_snapshot = snapshot.to_json
  end
  
  def capture_trade_defender_penalties
    penalties_snapshot = {}
    
    user.mt5_accounts.each do |account|
      unauthorized_trades = account.trades.where(trade_originality: 'manual_client')
      
      if unauthorized_trades.any?
        penalties_snapshot[account.mt5_id] = {
          account_name: account.account_name,
          total_penalty: unauthorized_trades.sum { |t| t.profit.abs },
          trades_count: unauthorized_trades.count,
          trades: unauthorized_trades.limit(20).order(close_time: :desc).map do |trade|
            {
              trade_id: trade.trade_id,
              symbol: trade.symbol,
              profit: trade.profit,
              close_time: trade.close_time.to_s
            }
          end
        }
      end
    end
    
    self.trade_defender_penalties_snapshot = penalties_snapshot.to_json if penalties_snapshot.any?
    save!
  end

  def update_watermarks_on_validation
    user.mt5_accounts.each do |account|
      # Lors de la validation d'un paiement, on met le watermark à la balance actuelle
      # pour que la commission due retombe à 0
      account.update!(high_watermark: account.balance)
    end
  end
end

