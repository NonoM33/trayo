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

  def update_watermarks_on_validation
    user.mt5_accounts.each do |account|
      account.update!(high_watermark: account.balance) if account.balance > account.high_watermark
    end
  end
end

