class Payment < ApplicationRecord
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending validated rejected] }

  scope :validated, -> { where(status: "validated") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(payment_date: :desc) }

  def validate!
    update!(status: "validated")
  end

  def reject!
    update!(status: "rejected")
  end
end

