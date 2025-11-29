class SmsCampaignLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :sent_by, class_name: 'User', optional: true
  belongs_to :sms_campaign, optional: true

  STATUSES = %w[sent delivered failed].freeze

  validates :message, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(sent_at: :desc) }
  scope :sent, -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }

  def type_label
    SmsCampaign::SMS_TYPES.include?(sms_type) ? SmsCampaign.new(sms_type: sms_type).type_label : sms_type
  end
end

