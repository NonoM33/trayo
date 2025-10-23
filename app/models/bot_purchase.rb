class BotPurchase < ApplicationRecord
  belongs_to :user
  belongs_to :trading_bot

  validates :price_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(created_at: :desc) }
end

