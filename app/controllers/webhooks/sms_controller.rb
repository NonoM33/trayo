class Webhooks::SmsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    Rails.logger.info("[SmsWebhook] ========== WEBHOOK RECEIVED ==========")
    Rails.logger.info("[SmsWebhook] Raw params: #{params.inspect}")
    
    body_content = request.body.read
    request.body.rewind
    Rails.logger.info("[SmsWebhook] Request body: #{body_content}")
    Rails.logger.info("[SmsWebhook] Content-Type: #{request.content_type}")
    
    webhook_data = webhook_params(body_content)
    Rails.logger.info("[SmsWebhook] Parsed params: #{webhook_data.inspect}")
    
    handler = SmsWebhookHandler.new(webhook_data)
    handler.process

    Rails.logger.info("[SmsWebhook] ========== WEBHOOK PROCESSED ==========")
    head :ok
  rescue => e
    Rails.logger.error("[SmsWebhook] ========== WEBHOOK ERROR ==========")
    Rails.logger.error("[SmsWebhook] Error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    head :ok # Retourner 200 pour éviter les retries
  end

  private

  def webhook_params(body_content = nil)
    # Accepter différents formats de paramètres
    # Si les données sont dans le body JSON, les parser
    if body_content.present? && (request.content_type&.include?('application/json') || body_content.strip.start_with?('{'))
      begin
        parsed = JSON.parse(body_content)
        parsed.deep_symbolize_keys
      rescue JSON::ParserError => e
        Rails.logger.warn("[SmsWebhook] JSON parse error: #{e.message}, falling back to params")
        params.permit(:id, :event, :phoneNumber, :phone, :text, :message, :messageId, textMessage: [:text]).to_h.deep_symbolize_keys
      end
    else
      params.permit(:id, :event, :phoneNumber, :phone, :text, :message, :messageId, textMessage: [:text]).to_h.deep_symbolize_keys
    end
  end
end

