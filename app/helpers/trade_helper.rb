module TradeHelper
  # Helper pour récupérer le nom du bot à partir du magic number
  # Optimisé pour éviter les requêtes N+1
  def bot_name_for_magic_number(magic_number, bots_cache = nil)
    return nil unless magic_number.present?
    
    # Utiliser le cache si fourni
    if bots_cache
      bot = bots_cache.find { |b| b.magic_number_prefix == magic_number }
      return bot.name if bot.present?
    else
      # Fallback vers la méthode du modèle
      bot = TradingBot.find_by(magic_number_prefix: magic_number)
      return bot.name if bot.present?
    end
    
    # Si aucun bot trouvé, retourner le magic number formaté
    "Bot #{magic_number}"
  end
  
  # Helper pour précharger tous les bots avec magic_number_prefix
  def preload_bots_with_magic_numbers
    TradingBot.where.not(magic_number_prefix: nil)
  end
end
