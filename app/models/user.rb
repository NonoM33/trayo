class User < ApplicationRecord
  has_secure_password

  has_many :mt5_accounts, dependent: :destroy
  has_many :trades, through: :mt5_accounts

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :mt5_api_token, uniqueness: true, allow_nil: true

  before_create :generate_mt5_api_token

  private

  def generate_mt5_api_token
    self.mt5_api_token = SecureRandom.hex(32)
  end
end

