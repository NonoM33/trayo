class Credit < ApplicationRecord
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :recent, -> { order(created_at: :desc) }
end

