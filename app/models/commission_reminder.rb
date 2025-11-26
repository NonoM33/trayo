class CommissionReminder < ApplicationRecord
  KINDS = %w[initial follow_up_24h follow_up_2h manual].freeze
  STATUSES = %w[pending sent failed skipped].freeze

  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def status_label
    status.humanize
  end

  def short_message
    return "-" if message_content.blank?
    message_content.truncate(80)
  end
end

