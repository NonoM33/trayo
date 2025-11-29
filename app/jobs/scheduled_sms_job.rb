class ScheduledSmsJob < ApplicationJob
  queue_as :default

  def perform
    ScheduledSms.due.find_each do |sms|
      sms.send_now!
    end
  end
end

