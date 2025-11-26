class CommissionReminderScheduleJob < ApplicationJob
  queue_as :default

  def perform(date = Time.current)
    return unless date.day == 14

    users_without_phone = []
    User.clients.find_each do |user|
      if user.phone.blank?
        users_without_phone << user.id
        next
      end

      next unless user.total_commission_due.to_f.positive?

      CommissionReminderDispatchJob.perform_later(user.id, kind: "initial")
    end

    Rails.logger.info("[CommissionReminderScheduleJob] Missing phone for users: #{users_without_phone.join(', ')}") if users_without_phone.any?
  end
end

