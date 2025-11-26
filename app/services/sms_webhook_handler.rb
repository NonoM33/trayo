class SmsWebhookHandler
  AIDE_KEYWORD = "aide"
  HELP_KEYWORD = "help"

  def initialize(payload)
    @payload = payload
    # Le webhook envoie les données dans différents formats possibles
    # Format 1: { event: "sms:received", phoneNumber: "...", textMessage: { text: "..." } }
    # Format 2: { phoneNumber: "...", text: "..." }
    phone_raw = payload[:phoneNumber] || payload["phoneNumber"] || payload[:phone] || payload["phone"]
    text_msg = payload[:textMessage] || payload["textMessage"] || {}
    @phone_number = normalize_phone(phone_raw)
    @message_text = text_msg[:text] || text_msg["text"] || payload[:text] || payload["text"] || payload[:message] || payload["message"]
    @message_id = payload[:id] || payload["id"] || payload[:messageId] || payload["messageId"]
    @event = payload[:event] || payload["event"]
  end

  def process
    Rails.logger.info("[SmsWebhookHandler] Processing webhook")
    Rails.logger.info("[SmsWebhookHandler] Payload: #{@payload.inspect}")
    Rails.logger.info("[SmsWebhookHandler] Phone: #{@phone_number.inspect}")
    Rails.logger.info("[SmsWebhookHandler] Message text: #{@message_text.inspect}")
    
    return unless @message_text.present?

    message_lower = @message_text.downcase.strip
    Rails.logger.info("[SmsWebhookHandler] Message lower: #{message_lower.inspect}")

    # Chercher l'utilisateur par numéro de téléphone
    user = find_user_by_phone
    Rails.logger.info("[SmsWebhookHandler] User found: #{user&.email || 'none'}")

    case message_lower
    when AIDE_KEYWORD, HELP_KEYWORD
      Rails.logger.info("[SmsWebhookHandler] Handling 'aide' request")
      handle_aide_request(user)
    else
      Rails.logger.info("[SmsWebhookHandler] Handling follow-up message")
      handle_follow_up_message(user, message_lower)
    end
  rescue => e
    Rails.logger.error("[SmsWebhookHandler] Error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end

  private

  def find_user_by_phone
    User.find_by(phone: @phone_number) || 
    User.find_by(phone: @phone_number.gsub("+33", "0")) ||
    User.find_by(phone: @phone_number.gsub("+33", ""))
  end

  def handle_aide_request(user)
    # Si l'utilisateur envoie "aide", on lui demande d'expliquer son problème
    response_text = if user
      "Bonjour #{user.first_name}, merci de nous contacter. Pouvez-vous nous expliquer votre problème en détail ?"
    else
      "Bonjour, merci de nous contacter. Pouvez-vous nous expliquer votre problème en détail ?"
    end

    send_response(response_text)
    
    # Créer un ticket en attente de description
    create_pending_ticket(user, "Demande d'aide - en attente de description")
  end

  def handle_follow_up_message(user, message_text)
    Rails.logger.info("[SmsWebhookHandler] Handling follow-up message: #{message_text}")
    
    # Chercher un ticket ouvert récent pour cet utilisateur/numéro
    ticket = find_recent_open_ticket(user)
    Rails.logger.info("[SmsWebhookHandler] Found ticket: #{ticket&.id}, status: #{ticket&.status}, description: #{ticket&.description&.truncate(50)}")

    # Vérifier si c'est un ticket en attente de description (insensible à la casse)
    is_pending_ticket = ticket && 
                        ticket.status == "open" && 
                        ticket.description.present? && 
                        ticket.description.downcase.include?("en attente de description")
    
    Rails.logger.info("[SmsWebhookHandler] Is pending ticket: #{is_pending_ticket}")

    if is_pending_ticket
      Rails.logger.info("[SmsWebhookHandler] Updating existing ticket with description")
      # C'est la réponse à la demande d'aide
      update_ticket_with_description(ticket, @message_text) # Utiliser le message original, pas le lowercased
      send_ticket_confirmation(ticket, user)
    else
      Rails.logger.info("[SmsWebhookHandler] Creating new ticket from message")
      # Nouveau message, créer un ticket
      create_ticket_from_message(user, @message_text) # Utiliser le message original
    end
  end

  def find_recent_open_ticket(user)
    # Chercher un ticket ouvert récent (moins de 48h) pour ce numéro
    # On cherche d'abord les tickets en attente de description (insensible à la casse)
    scope = SupportTicket.open
                         .where(phone_number: @phone_number)
                         .where("created_at > ?", 48.hours.ago)
                         .where("LOWER(description) LIKE ?", "%en attente de description%")
    
    # Si on a un user, prioriser les tickets de cet utilisateur
    if user
      user_ticket = scope.where(user: user).recent.first
      return user_ticket if user_ticket
    end
    
    # Sinon, prendre le plus récent pour ce numéro
    ticket = scope.recent.first
    Rails.logger.info("[SmsWebhookHandler] Found ticket in DB: #{ticket&.id}, description: #{ticket&.description&.truncate(50)}")
    ticket
  end

  def create_pending_ticket(user, subject)
    SupportTicket.create!(
      user: user,
      phone_number: @phone_number,
      status: "open",
      subject: subject,
      description: "En attente de description du problème",
      sms_message_id: @message_id,
      created_via: "sms"
    )
  end

  def update_ticket_with_description(ticket, description)
    ticket.update!(
      description: description,
      subject: "Demande d'aide - #{description.truncate(50)}",
      status: "open"
    )
  end

  def create_ticket_from_message(user, message_text)
    ticket = SupportTicket.create!(
      user: user,
      phone_number: @phone_number,
      status: "open",
      subject: "Message SMS - #{message_text.truncate(50)}",
      description: message_text,
      sms_message_id: @message_id,
      created_via: "sms"
    )

    send_ticket_confirmation(ticket, user)
    ticket
  end

  def send_ticket_confirmation(ticket, user)
    base_url = ENV.fetch("APP_BASE_URL", Rails.application.routes.url_helpers.root_url(host: ENV.fetch("HOST", "localhost:3000")))
    ticket_url = "#{base_url.chomp('/')}/ticket/#{ticket.public_token}"
    
    response_text = if user
      "Bonjour #{user.first_name}, votre demande a bien été prise en compte.\n\n📋 Numéro de ticket : #{ticket.ticket_number}\n🔗 Suivez votre ticket : #{ticket_url}\n\nNotre équipe vous répondra dans les plus brefs délais."
    else
      "Votre demande a bien été prise en compte.\n\n📋 Numéro de ticket : #{ticket.ticket_number}\n🔗 Suivez votre ticket : #{ticket_url}\n\nNotre équipe vous répondra dans les plus brefs délais."
    end

    send_response(response_text)
  end

  def send_response(text)
    SmsGateway.send_message(
      phone_numbers: @phone_number,
      text: text
    )
  end

  def normalize_phone(phone)
    return nil if phone.blank?

    cleaned = phone.to_s.gsub(/\s+/, "")
    
    if cleaned.start_with?("+33")
      cleaned
    elsif cleaned.start_with?("33") && cleaned.length >= 11
      "+#{cleaned}"
    elsif cleaned.start_with?("0")
      "+33#{cleaned[1..-1]}"
    else
      "+33#{cleaned}"
    end
  end
end

