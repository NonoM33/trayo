class Withdrawal < ApplicationRecord
  belongs_to :mt5_account

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :withdrawal_date, presence: true

  scope :recent, -> { order(withdrawal_date: :desc) }

  after_create :adjust_watermark

  private

  def adjust_watermark
    mt5_account.increment!(:total_withdrawals, amount)
    # Le watermark n'est plus mis à jour automatiquement, seulement via les paiements
  end
end

