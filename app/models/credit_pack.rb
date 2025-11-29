class CreditPack < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :bonus_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, amount: :asc) }

  def bonus_amount
    (amount * bonus_percentage / 100.0).round
  end

  def total_credits
    amount + bonus_amount
  end

  def formatted_label
    label.presence || "Pack #{amount}€"
  end

  def self.seed_defaults!
    [
      { amount: 500, bonus_percentage: 5, position: 1 },
      { amount: 1000, bonus_percentage: 6, is_popular: true, position: 2 },
      { amount: 1500, bonus_percentage: 7, position: 3 },
      { amount: 2000, bonus_percentage: 8, position: 4 },
      { amount: 5000, bonus_percentage: 10, is_best: true, position: 5 }
    ].each do |pack_data|
      find_or_create_by!(amount: pack_data[:amount]) do |pack|
        pack.assign_attributes(pack_data.merge(active: true))
      end
    end
  end
end
