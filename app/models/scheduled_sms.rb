class ScheduledSms < ApplicationRecord
  belongs_to :user
  belongs_to :created_by, class_name: 'User', optional: true

  STATUSES = %w[pending sent failed cancelled].freeze

  validates :message, presence: true
  validates :scheduled_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending') }
  scope :due, -> { pending.where('scheduled_at <= ?', Time.current) }
  scope :upcoming, -> { pending.where('scheduled_at > ?', Time.current).order(:scheduled_at) }
  scope :recent, -> { order(created_at: :desc) }

  def send_now!
    return if status != 'pending'

    begin
      SmsService.send_sms(phone_number || user.phone, message)
      
      SmsCampaignLog.create(
        user: user,
        sent_by: created_by,
        sms_type: sms_type,
        message: message,
        phone_number: phone_number || user.phone,
        status: 'sent',
        sent_at: Time.current
      )

      update!(status: 'sent', sent_at: Time.current)
    rescue => e
      update!(status: 'failed', error_message: e.message)
    end
  end

  def cancel!
    update!(status: 'cancelled') if pending?
  end

  def pending?
    status == 'pending'
  end

  def time_until_send
    return nil unless pending? && scheduled_at > Time.current
    scheduled_at - Time.current
  end
end

