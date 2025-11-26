class Invoice < ApplicationRecord
  STATUSES = %w[pending partial paid cancelled].freeze

  belongs_to :user
  has_many :invoice_items, dependent: :destroy
  has_many :invoice_payments, dependent: :destroy
  has_many :bot_purchases, dependent: :nullify
  has_many :vps, class_name: "Vps", dependent: :nullify

  before_validation :assign_reference, on: :create
  after_commit :sync_related_records, on: [:create, :update]

  validates :reference, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :partial, -> { where(status: "partial") }

  def add_item(label:, unit_price:, quantity: 1, item_type: nil, item_id: nil, metadata: nil)
    invoice_items.create!(
      label: label,
      unit_price: unit_price,
      quantity: quantity,
      total_price: unit_price.to_f * quantity.to_i,
      item_type: item_type,
      item_id: item_id,
      metadata: metadata
    )
    recalculate_totals!
  end

  def recalculate_totals!
    total = invoice_items.sum(:total_price)
    paid = invoice_payments.sum(:amount)
    new_status = if total.zero?
      "pending"
    elsif paid <= 0
      "pending"
    elsif paid < total
      "partial"
    else
      "paid"
    end

    update!(
      total_amount: total.round(2),
      balance_due: [total - paid, 0].max.round(2),
      status: new_status
    )
  end

  def register_payment!(amount:, payment_method:, paid_at: Time.current, notes: nil, recorded_by: nil)
    invoice_payments.create!(
      amount: amount,
      payment_method: payment_method,
      paid_at: paid_at,
      notes: notes,
      recorded_by: recorded_by
    )
    recalculate_totals!
  end

  def pending?
    status == "pending"
  end

  def partial?
    status == "partial"
  end

  def paid?
    status == "paid"
  end

  def status_badge
    case status
    when "paid" then { label: "Réglée", color: "#16a34a" }
    when "partial" then { label: "Partielle", color: "#facc15" }
    when "cancelled" then { label: "Annulée", color: "#9ca3af" }
    else
      { label: "À régler", color: "#f87171" }
    end
  end

  private

  def assign_reference
    return if reference.present?

    token = SecureRandom.hex(4).upcase
    self.reference = "INV-#{Time.current.strftime('%Y%m%d')}-#{token}"
  end

  def sync_related_records
    case status
    when "paid"
      bot_purchases.update_all(billing_status: "paid", status: "active")
      vps.update_all(billing_status: "paid")
    when "partial"
      bot_purchases.where.not(billing_status: "paid").update_all(billing_status: "partial")
      vps.where.not(billing_status: "paid").update_all(billing_status: "partial")
    else
      bot_purchases.where.not(billing_status: "paid").update_all(billing_status: "pending")
      vps.where.not(billing_status: "paid").update_all(billing_status: "pending")
    end
  end
end

