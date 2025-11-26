namespace :sms do
  desc "Enregistrer le webhook SMS"
  task register_webhook: :environment do
    webhook_url = ENV.fetch("SMS_WEBHOOK_URL", "https://your-domain.com/webhooks/sms")
    device_id = ENV.fetch("SMS_GATEWAY_DEVICE_ID", "kHm2-bFyrL7vsjkPqXngD")
    webhook_id = ENV.fetch("SMS_WEBHOOK_ID", SecureRandom.uuid)

    puts "Enregistrement du webhook SMS..."
    puts "URL: #{webhook_url}"
    puts "Device ID: #{device_id}"
    puts "Webhook ID: #{webhook_id}"

    result = SmsGateway.register_webhook(
      webhook_url: webhook_url,
      event: "sms:received",
      device_id: device_id,
      webhook_id: webhook_id
    )

    if result[:status].between?(200, 299)
      puts "✅ Webhook enregistré avec succès!"
      puts "Réponse: #{result[:body]}"
    else
      puts "❌ Erreur lors de l'enregistrement: #{result[:status]}"
      puts "Réponse: #{result[:body]}"
    end
  end

  desc "Lister les webhooks enregistrés"
  task list_webhooks: :environment do
    puts "Récupération de la liste des webhooks..."
    
    webhooks = SmsGateway.list_webhooks
    
    if webhooks.is_a?(Array)
      puts "Webhooks enregistrés:"
      webhooks.each do |webhook|
        puts "  - ID: #{webhook['id']}"
        puts "    URL: #{webhook['url']}"
        puts "    Event: #{webhook['event']}"
        puts "    Device ID: #{webhook['deviceId']}"
        puts ""
      end
    else
      puts "Aucun webhook trouvé ou erreur: #{webhooks.inspect}"
    end
  end
end

