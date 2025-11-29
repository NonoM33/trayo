class CommissionInvoice < ApplicationRecord
  belongs_to :user
  belongs_to :invoice, optional: true

  STATUSES = %w[pending reminder_sent processing paid failed overdue].freeze
  LATE_FEE = 120.00

  validates :reference, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :commission_rate, presence: true
  validates :total_amount, presence: true

  scope :pending, -> { where(status: 'pending') }
  scope :unpaid, -> { where(status: %w[pending reminder_sent failed overdue]) }
  scope :paid, -> { where(status: 'paid') }
  scope :overdue, -> { where(status: 'overdue') }
  scope :due_today, -> { where(due_date: Date.current.all_day) }
  scope :reminder_needed, -> { pending.where(due_date: 1.day.from_now.all_day).where(reminder_sent_at: nil) }

  before_validation :generate_reference, on: :create

  def pending?
    status == 'pending'
  end

  def paid?
    status == 'paid'
  end

  def overdue?
    status == 'overdue'
  end

  def failed?
    status == 'failed'
  end

  def mark_as_paid!(payment_intent_id = nil)
    update!(
      status: 'paid',
      paid_at: Time.current,
      stripe_payment_intent_id: payment_intent_id
    )
    
    user.update!(
      commission_balance_due: 0,
      commission_payment_failed: false,
      commission_payment_failed_at: nil,
      bots_suspended_for_payment: false
    )

    reactivate_user_bots! if user.bots_suspended_for_payment_was
  end

  def mark_as_failed!
    update!(status: 'failed')
    
    user.update!(
      commission_payment_failed: true,
      commission_payment_failed_at: Time.current
    )
  end

  def mark_as_overdue!
    return if overdue?
    
    update!(
      status: 'overdue',
      late_fee: LATE_FEE,
      total_amount: commission_amount + LATE_FEE
    )
    
    user.update!(
      commission_balance_due: total_amount,
      bots_suspended_for_payment: true
    )

    suspend_user_bots!
  end

  def send_reminder!
    return if reminder_sent_at.present?

    message = "TRAYO: Votre commission de #{format_currency(commission_amount)} sera prélevée demain. Assurez-vous d'avoir les fonds disponibles."
    SmsService.send_sms(user.phone, message) if user.phone.present?
    
    update!(reminder_sent_at: Time.current, status: 'reminder_sent')
  end

  def send_payment_link!
    payment_url = Rails.application.routes.url_helpers.pay_commission_url(token: generate_payment_token, host: ENV.fetch('APP_HOST', 'localhost:3000'))
    
    message = "TRAYO: Échec du prélèvement de #{format_currency(total_amount)}. Réglez ici: #{payment_url}"
    SmsService.send_sms(user.phone, message) if user.phone.present?
  end

  def hours_since_failure
    return 0 unless commission_payment_failed_at = user.commission_payment_failed_at
    ((Time.current - commission_payment_failed_at) / 1.hour).to_i
  end

  def should_apply_late_fee?
    hours_since_failure >= 48 && late_fee == 0
  end

  private

  def generate_reference
    self.reference ||= "COM-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def generate_payment_token
    SecureRandom.urlsafe_base64(32)
  end

  def format_currency(amount)
    "#{amount.to_f.round(2)}€"
  end

  def suspend_user_bots!
    user.bot_purchases.where(is_running: true).update_all(is_running: false)
    Rails.logger.info "Suspended bots for user #{user.id} due to commission payment failure"
  end

  def reactivate_user_bots!
    user.bot_purchases.where(status: 'active').update_all(is_running: true)
    Rails.logger.info "Reactivated bots for user #{user.id} after commission payment"
  end
end

