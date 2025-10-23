class User < ApplicationRecord
  has_secure_password

  has_many :mt5_accounts, dependent: :destroy
  has_many :trades, through: :mt5_accounts
  has_many :payments, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :bonus_deposits, dependent: :destroy
  has_many :bot_purchases, dependent: :destroy
  has_many :trading_bots, through: :bot_purchases

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :mt5_api_token, uniqueness: true, allow_nil: true
  validates :commission_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  before_create :generate_mt5_api_token

  scope :clients, -> { where(is_admin: false) }
  scope :admins, -> { where(is_admin: true) }

  def total_profits
    mt5_accounts.reload.sum { |account| account.net_gains }
  end

  def total_commissionable_gains
    mt5_accounts.reload.sum { |account| account.commissionable_gains }
  end

  def total_commission_due
    return 0 if commission_rate.zero?
    (total_commissionable_gains * commission_rate / 100).round(2)
  end

  def total_validated_payments
    payments.validated.sum(:amount)
  end

  def total_credits
    credits.sum(:amount)
  end

  def balance_due
    (total_commission_due - total_credits).round(2)
  end

  def pending_payments_total
    payments.pending.sum(:amount)
  end

  private

  def generate_mt5_api_token
    self.mt5_api_token = SecureRandom.hex(32)
  end
end

