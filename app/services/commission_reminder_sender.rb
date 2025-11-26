class CommissionReminderSender
  PAYMENT_LINK = "https://revolut.me/renaudcosson".freeze
  FEE_AMOUNT = 120
  WINDOW_HOURS = 48

  Result = Struct.new(:success?, :message, :reminder, :data, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def call(kind: "initial", deadline: nil, force: false)
    payload = build_payload(kind: kind, deadline: deadline, force: force)

    reminder = @user.commission_reminders.create!(
      kind: kind,
      amount: payload[:amount],
      watermark_reference: payload[:watermark],
      deadline_at: payload[:deadline],
      phone_number: payload[:phone],
      status: "pending",
      message_content: payload[:text]
    )

    response = SmsGateway.send_message(
      phone_numbers: payload[:phone],
      text: payload[:text]
    )

    response_body = parse_body(response[:body])
    reminder.update!(
      status: response[:status].between?(200, 299) ? "sent" : "failed",
      response_payload: response[:body],
      sent_at: Time.current,
      external_id: response_body["id"]
    )

    Result.new(success?: true, reminder: reminder, data: payload, message: "SMS envoyé")
  rescue => e
    Rails.logger.error("[CommissionReminderSender] #{e.class}: #{e.message}")
    reminder&.update(status: "failed", error_message: e.message)
    Result.new(success?: false, reminder: reminder, message: e.message)
  end

  def preview(kind: "manual", deadline: nil)
    payload = build_payload(kind: kind, deadline: deadline, force: false, preview: true)
    Result.new(success?: true, data: payload, message: "Prévisualisation prête")
  rescue => e
    Result.new(success?: false, message: e.message)
  end

  private

  def build_payload(kind:, deadline:, force:, preview: false)
    raise "Aucun numéro renseigné" if @user.phone.blank?

    amount_due = @user.total_commission_due.to_f.round(2)
    raise "Aucune commission due" if amount_due <= 0 && !force

    watermark = @user.total_balance_snapshot
    deadline_at = deadline || WINDOW_HOURS.hours.from_now
    text = build_message(amount_due: amount_due, watermark: watermark, deadline_at: deadline_at, kind: kind)
    normalized_phone = normalize_phone_number(@user.phone)

    {
      amount: amount_due,
      watermark: watermark,
      deadline: deadline_at,
      phone: normalized_phone,
      text: text,
      kind: kind
    }
  end

  def build_message(amount_due:, watermark:, deadline_at:, kind:)
    deadline_str = deadline_at.strftime("%d/%m/%Y %H:%M")
    urgency =
      case kind
      when "follow_up_24h" then "⏳ Il reste 24h pour régulariser votre situation."
      when "follow_up_2h"  then "⚠️ Dernier rappel : il reste 2h !"
      else "Merci de bien vouloir régler sous 48h."
      end

    <<~MSG
      Bonjour #{@user.first_name},

      Vous avez un solde de commission à régler de #{format_amount(amount_due)}.

      #{urgency}

      Lien de paiement : #{PAYMENT_LINK}
      Réf : #{format_watermark(watermark.round())}

      (Merci d'indiquer OBLIGATOIREMENT cette référence dans la remarque du règlement, sinon le paiement ne sera pas pris en compte.)

      ⚠️ Après le #{deadline_str}, des frais de remise en service de #{format_amount(FEE_AMOUNT)} seront appliqués.

      Merci de votre compréhension. L'équipe Trayo
    MSG
    .strip
  end

  def format_amount(value)
    ActionController::Base.helpers.number_to_currency(value, unit: "€", format: "%n %u")
  end

  def format_watermark(value)
    "REF#{value.round(2)}"
  end

  def normalize_phone_number(phone)
    return phone if phone.blank?
    
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

  def parse_body(body)
    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end
end

