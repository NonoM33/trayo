class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  before_validation :apply_totals

  validates :label, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: true

  private

  def apply_totals
    qty = quantity || 1
    price = unit_price || 0
    self.total_price = (qty * price).round(2)
  end
end

