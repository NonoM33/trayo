class CommissionReminderScheduleJob < ApplicationJob
  queue_as :default

  def perform(date = Time.current)
    today = date.to_date
    day = today.day

    case day
    when 14
      send_initial_reminders(today)
    when 28
      send_follow_up_reminders(today)
    else
      Rails.logger.debug("[CommissionReminderScheduleJob] No action for day #{day}")
    end
  end

  private

  def send_initial_reminders(date)
    Rails.logger.info("[CommissionReminderScheduleJob] Sending initial reminders for #{date}")

    users_without_phone = []
    sent_count = 0

    User.clients.find_each do |user|
      if user.phone.blank?
        users_without_phone << user.id
        next
      end

      commission_due = user.total_commission_due.to_f
      next unless commission_due.positive?

      CommissionReminderDispatchJob.perform_later(user.id, kind: "initial")
      sent_count += 1
    end

    Rails.logger.info("[CommissionReminderScheduleJob] Initial reminders: #{sent_count} sent, #{users_without_phone.size} without phone")
    Rails.logger.info("[CommissionReminderScheduleJob] Missing phone for users: #{users_without_phone.join(', ')}") if users_without_phone.any?
  end

  def send_follow_up_reminders(date)
    Rails.logger.info("[CommissionReminderScheduleJob] Sending follow-up reminders for #{date}")

    # Chercher les rappels initiaux envoyés entre le 1er et le 27 du mois (pour éviter les doublons avec le 28)
    month_start = date.beginning_of_month
    month_end = date.beginning_of_day # Jusqu'au début du 28 (exclu)

    sent_count = 0
    skipped_count = 0
    no_initial_count = 0

    User.clients.find_each do |user|
      if user.phone.blank?
        next
      end

      commission_due = user.total_commission_due.to_f
      next unless commission_due.positive?

      # Vérifier qu'il y a eu un rappel initial ce mois-ci (entre le 1er et avant le 28)
      initial_reminder = user.commission_reminders
                            .where(kind: "initial")
                            .where("created_at >= ? AND created_at < ?", month_start, month_end)
                            .where(status: ["sent", "pending"])
                            .order(created_at: :desc)
                            .first

      unless initial_reminder
        no_initial_count += 1
        Rails.logger.debug("[CommissionReminderScheduleJob] User #{user.id}: no initial reminder found for this month")
        next
      end

      # Vérifier que la commission est toujours due (pas encore payée)
      if commission_due.positive?
        # Pour le rappel du 28, on fixe un nouveau deadline de 48h
        new_deadline = 48.hours.from_now
        CommissionReminderDispatchJob.perform_later(
          user.id,
          kind: "follow_up_28d",
          deadline: new_deadline,
          force: true,
          schedule_followups: false
        )
        sent_count += 1
        Rails.logger.debug("[CommissionReminderScheduleJob] User #{user.id}: follow-up reminder scheduled (initial reminder ID: #{initial_reminder.id})")
      else
        skipped_count += 1
        Rails.logger.debug("[CommissionReminderScheduleJob] User #{user.id}: commission already paid, skipping")
      end
    end

    Rails.logger.info("[CommissionReminderScheduleJob] Follow-up reminders: #{sent_count} sent, #{skipped_count} skipped (already paid), #{no_initial_count} skipped (no initial reminder)")
  end
end

