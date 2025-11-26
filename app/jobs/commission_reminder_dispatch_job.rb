class CommissionReminderDispatchJob < ApplicationJob
  queue_as :default

  def perform(user_id, kind: "initial", deadline: nil, force: false, schedule_followups: true)
    user = User.find_by(id: user_id)
    return unless user

    sender = CommissionReminderSender.new(user)
    result = sender.call(kind: kind, deadline: deadline, force: force)
    return unless result.success?

    reminder = result.reminder
    return unless schedule_followups && kind == "initial"

    schedule_follow_up_jobs(user, reminder.deadline_at)
  end

  private

  def schedule_follow_up_jobs(user, deadline_at)
    return unless deadline_at

    CommissionReminderDispatchJob
      .set(wait: 24.hours)
      .perform_later(user.id, kind: "follow_up_24h", deadline: deadline_at, schedule_followups: false)

    final_time = deadline_at - 2.hours
    if final_time > Time.current
      wait_seconds = final_time - Time.current
      CommissionReminderDispatchJob
        .set(wait: wait_seconds)
        .perform_later(user.id, kind: "follow_up_2h", deadline: deadline_at, schedule_followups: false)
    end
  end
end

