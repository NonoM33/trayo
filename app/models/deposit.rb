class Deposit < ApplicationRecord
  belongs_to :mt5_account

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :deposit_date, presence: true
  validates :transaction_id, uniqueness: { scope: :mt5_account_id }, allow_nil: true

  scope :recent, -> { order(deposit_date: :desc) }

  after_create :update_account_totals
  after_update :recalculate_account_initial_balance
  after_destroy :recalculate_account_initial_balance

  private

  def update_account_totals
    mt5_account.increment!(:total_deposits, amount)
    recalculate_account_initial_balance
  end

  def recalculate_account_initial_balance
    # Recalculer la balance initiale du compte MT5
    mt5_account.calculate_initial_balance_from_history
  end
end
