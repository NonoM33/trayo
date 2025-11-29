class SubscriptionReminderJob < ApplicationJob
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find_by(id: subscription_id)
    return unless subscription
    return unless subscription.past_due?

    SubscriptionService.send_payment_reminder(subscription)

    if subscription.failed_payment_count < 3
      SubscriptionReminderJob.set(wait: 24.hours).perform_later(subscription_id)
    end
  end
end

