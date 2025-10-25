class Deposit < ApplicationRecord
  belongs_to :mt5_account

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :deposit_date, presence: true
  validates :transaction_id, uniqueness: { scope: :mt5_account_id }, allow_nil: true

  scope :recent, -> { order(deposit_date: :desc) }

  after_create :update_account_totals

  private

  def update_account_totals
    mt5_account.increment!(:total_deposits, amount)
  end
end
