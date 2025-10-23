class BonusDeposit < ApplicationRecord
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :bonus_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :status, presence: true, inclusion: { in: %w[pending validated rejected] }

  before_validation :calculate_bonus, on: :create

  scope :validated, -> { where(status: "validated") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }

  def validate!
    update!(status: "validated")
    user.credits.create!(
      amount: total_credit,
      reason: "Bonus deposit: #{amount}$ + #{bonus_percentage}% bonus = #{total_credit}$"
    )
  end

  def reject!
    update!(status: "rejected")
  end

  private

  def calculate_bonus
    self.bonus_amount = (amount * bonus_percentage / 100).round(2)
    self.total_credit = (amount + bonus_amount).round(2)
  end
end

