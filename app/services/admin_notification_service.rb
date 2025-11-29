class AdminNotificationService
  class << self
    def notify(title:, message:, level: :info, metadata: {})
      Rails.logger.tagged("AdminNotification") do
        Rails.logger.send(log_level(level), "#{title}: #{message}")
      end

      admin_phone = ENV.fetch('ADMIN_PHONE', nil)
      if admin_phone.present? && level.to_sym.in?([:warning, :error])
        send_admin_sms(title, message, admin_phone)
      end

      admin_email = ENV.fetch('ADMIN_EMAIL', nil)
      if admin_email.present?
        send_admin_email(title, message, level, admin_email, metadata)
      end

      broadcast_notification(title, message, level, metadata)
    end

    private

    def log_level(level)
      case level.to_sym
      when :error then :error
      when :warning then :warn
      else :info
      end
    end

    def send_admin_sms(title, message, phone)
      sms_text = "#{title}\n#{message.truncate(140)}"
      SmsService.send_sms(to: phone, message: sms_text)
    rescue => e
      Rails.logger.error "Failed to send admin SMS: #{e.message}"
    end

    def send_admin_email(title, message, level, email, metadata)
      AdminMailer.notification(
        to: email,
        subject: "[#{level.to_s.upcase}] #{title}",
        body: message,
        metadata: metadata
      ).deliver_later
    rescue => e
      Rails.logger.error "Failed to send admin email: #{e.message}"
    end

    def broadcast_notification(title, message, level, metadata)
      ActionCable.server.broadcast(
        "admin_notifications",
        {
          type: 'notification',
          level: level,
          title: title,
          message: message,
          metadata: metadata,
          timestamp: Time.current.iso8601
        }
      )
    rescue => e
      Rails.logger.error "Failed to broadcast notification: #{e.message}"
    end
  end
end

