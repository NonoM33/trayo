module Invoices
  class Builder
    attr_reader :user, :source, :due_in_days, :due_date, :metadata, :deactivate_bots

    def initialize(user:, source:, due_in_days: 7, due_date: nil, metadata: {}, deactivate_bots: true)
      @user = user
      @source = source
      @due_in_days = due_in_days
      @due_date = due_date
      @metadata = metadata
      @deactivate_bots = deactivate_bots
    end

    def build_from_selection(bot_purchases:, vps_list: [])
      bot_records = normalize_bot_records(bot_purchases)
      vps_records = normalize_vps_records(vps_list)

      raise ArgumentError, "Aucun élément sélectionné pour la facture" if bot_records.empty? && vps_records.empty?

      invoice = user.invoices.create!(
        source: source,
        due_date: due_date || Date.current + due_in_days,
        metadata: metadata,
        vps_included: vps_records.any?
      )

      bot_records.each do |purchase|
        invoice.add_item(
          label: purchase.trading_bot.name,
          unit_price: purchase.price_paid,
          quantity: 1,
          item_type: "BotPurchase",
          item_id: purchase.id,
          metadata: { bot_id: purchase.trading_bot_id }
        )
        purchase.update!(
          invoice: invoice,
          billing_status: "pending",
          status: deactivate_bots ? "inactive" : purchase.status
        )
      end

      vps_records.each do |vps|
        annual_price = (vps.monthly_price || 0).to_f.round(2)
        invoice.add_item(
          label: "Abonnement VPS (12 mois)",
          unit_price: annual_price,
          quantity: 1,
          item_type: "Vps",
          item_id: vps.id,
          metadata: { vps_id: vps.id }
        )
        vps.update!(invoice: invoice, billing_status: "pending")
      end

      invoice.recalculate_totals!
      invoice
    end

    private

    def normalize_bot_records(records)
      Array(records).compact.map do |record|
        case record
        when BotPurchase
          record
        when Integer, String
          user.bot_purchases.find_by(id: record)
        else
          nil
        end
      end.compact
    end

    def normalize_vps_records(records)
      Array(records).compact.map do |record|
        case record
        when Vps
          record
        when Integer, String
          user.vps.find_by(id: record)
        else
          nil
        end
      end.compact
    end
  end
end

