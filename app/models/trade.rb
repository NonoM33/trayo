class Trade < ApplicationRecord
  belongs_to :mt5_account

  validates :trade_id, presence: true, uniqueness: { scope: :mt5_account_id }

  scope :closed, -> { where(status: "closed") }
  scope :recent, -> { order(close_time: :desc) }

  # Méthode pour récupérer le nom du bot à partir du magic number
  def bot_name
    return nil unless magic_number.present?
    
    # Chercher un bot qui a ce magic number comme prefix
    bot = TradingBot.find_by(magic_number_prefix: magic_number)
    return bot.name if bot.present?
    
    # Si pas trouvé, chercher par correspondance partielle (pour les magic numbers plus longs)
    bot = TradingBot.where("magic_number_prefix IS NOT NULL")
                    .find { |b| magic_number.to_s.start_with?(b.magic_number_prefix.to_s) }
    return bot.name if bot.present?
    
    # Si aucun bot trouvé, retourner le magic number formaté
    "Bot #{magic_number}"
  end

  def self.create_or_update_from_mt5(mt5_account, trade_data)
    trade = find_or_initialize_by(
      mt5_account: mt5_account,
      trade_id: trade_data[:trade_id]
    )

    trade.assign_attributes(
      symbol: trade_data[:symbol],
      trade_type: trade_data[:trade_type],
      volume: trade_data[:volume],
      open_price: trade_data[:open_price],
      close_price: trade_data[:close_price],
      profit: trade_data[:profit],
      commission: trade_data[:commission],
      swap: trade_data[:swap],
      open_time: trade_data[:open_time],
      close_time: trade_data[:close_time],
      status: trade_data[:status],
      magic_number: trade_data[:magic_number],
      comment: trade_data[:comment]
    )

    trade.save!
    trade
  end
end

