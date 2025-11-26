class InvoicePayment < ApplicationRecord
  belongs_to :invoice
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :amount, numericality: { greater_than: 0 }
  validates :paid_at, presence: true

  after_create_commit :refresh_invoice

  private

  def refresh_invoice
    invoice.recalculate_totals!
  end
end

