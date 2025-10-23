class TradingBot < ApplicationRecord
  has_many :bot_purchases, dependent: :destroy
  has_many :users, through: :bot_purchases

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  scope :active, -> { where(status: "active") }
  scope :featured, -> { where("features @> ?", { featured: true }.to_json) }
end

