require "net/http"
require "json"

class SmsGateway
  API_URL = URI("https://api.sms-gate.app/3rdparty/v1/messages").freeze
  STATUS_URL = URI("https://api.sms-gate.app/3rdparty/v1/messages/status").freeze
  DEFAULT_DEVICE_ID = ENV.fetch("SMS_GATEWAY_DEVICE_ID", "kHm2-bFyrL7vsjkPqXngD")
  DEFAULT_USER = ENV.fetch("SMS_GATEWAY_USER", "EZMOAP")
  DEFAULT_PASSWORD = ENV.fetch("SMS_GATEWAY_PASSWORD", "mx3yvylh7y-8-o")

  def self.send_message(phone_numbers:, text:, device_id: DEFAULT_DEVICE_ID)
    body = {
      deviceId: device_id,
      phoneNumbers: Array(phone_numbers),
      textMessage: {
        text: text
      }
    }

    response = perform_request(API_URL, body)
    { status: response.code.to_i, body: response.body }
  rescue => e
    Rails.logger.error("[SmsGateway] #{e.class}: #{e.message}")
    raise
  end

  def self.message_status(message_id)
    url = STATUS_URL.dup
    url.query = URI.encode_www_form(id: message_id)
    response = perform_request(url, nil, method: :get)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("[SmsGateway#status] #{e.class}: #{e.message}")
    {}
  end

  def self.register_webhook(webhook_url:, event: "sms:received", device_id: DEFAULT_DEVICE_ID, webhook_id: nil)
    webhook_id ||= SecureRandom.uuid
    
    body = {
      deviceId: device_id,
      event: event,
      id: webhook_id,
      url: webhook_url
    }

    webhook_uri = URI("https://api.sms-gate.app/3rdparty/v1/webhooks")
    response = perform_request(webhook_uri, body, method: :post)
    { status: response.code.to_i, body: response.body }
  rescue => e
    Rails.logger.error("[SmsGateway] Webhook registration error: #{e.class}: #{e.message}")
    raise
  end

  def self.list_webhooks
    webhook_uri = URI("https://api.sms-gate.app/3rdparty/v1/webhooks")
    response = perform_request(webhook_uri, nil, method: :get)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("[SmsGateway] Webhook list error: #{e.class}: #{e.message}")
    {}
  end

  def self.perform_request(uri, body = nil, method: :post)
    request = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
    request.basic_auth(DEFAULT_USER, DEFAULT_PASSWORD)
    request["Content-Type"] = "application/json"
    request.body = body.to_json if body

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end
  private_class_method :perform_request
end

