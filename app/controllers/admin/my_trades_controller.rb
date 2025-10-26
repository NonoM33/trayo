module Admin
  class MyTradesController < BaseController
    def index
      # Récupérer tous les trades de l'utilisateur connecté
      @trades = Trade.joins(:mt5_account)
                    .where(mt5_accounts: { user_id: current_user.id })
                    .includes(:mt5_account)
                    .order(close_time: :desc)
      
      # Précharger les bots pour optimiser les performances
      @bots_cache = TradingBot.where.not(magic_number_prefix: nil)
      
      # Filtres
      if params[:symbol].present?
        @trades = @trades.where('symbol ILIKE ?', "%#{params[:symbol]}%")
      end
      
      if params[:magic_number].present?
        @trades = @trades.where(magic_number: params[:magic_number])
      end
      
      if params[:status].present?
        @trades = @trades.where(status: params[:status])
      end
      
      if params[:date_from].present?
        @trades = @trades.where('close_time >= ?', Date.parse(params[:date_from]).beginning_of_day)
      end
      
      if params[:date_to].present?
        @trades = @trades.where('close_time <= ?', Date.parse(params[:date_to]).end_of_day)
      end
      
      # Statistiques globales (calculées AVANT pagination)
      @total_trades = @trades.count
      @total_profit = @trades.sum(:profit)
      @winning_trades = @trades.where('profit > 0').count
      @losing_trades = @trades.where('profit < 0').count
      @win_rate = @total_trades > 0 ? (@winning_trades.to_f / @total_trades * 100).round(2) : 0
      
      # Statistiques par bot
      @bot_stats = calculate_bot_statistics(@trades, @bots_cache)
      
      # Statistiques par symbole
      @symbol_stats = calculate_symbol_statistics(@trades)
      
      # Tri
      case params[:sort]
      when 'symbol'
        @trades = @trades.order(:symbol, close_time: :desc)
      when 'profit'
        @trades = @trades.order(:profit)
      when 'magic_number'
        @trades = @trades.order(:magic_number, close_time: :desc)
      when 'close_time'
        @trades = @trades.order(close_time: :desc)
      else
        @trades = @trades.order(close_time: :desc)
      end
      
      # Pagination (après calcul des statistiques)
      @trades = @trades.page(params[:page]).per(50)
    end
    
    private
    
    def calculate_bot_statistics(trades, bots_cache)
      stats = {}
      
      trades.group_by(&:magic_number).each do |magic_number, bot_trades|
        next if magic_number.blank?
        
        bot_name = bot_name_for_magic_number(magic_number, bots_cache)
        
        stats[bot_name] = {
          magic_number: magic_number,
          total_trades: bot_trades.count,
          total_profit: bot_trades.sum(&:profit),
          winning_trades: bot_trades.count { |t| t.profit > 0 },
          losing_trades: bot_trades.count { |t| t.profit < 0 },
          win_rate: bot_trades.count > 0 ? (bot_trades.count { |t| t.profit > 0 }.to_f / bot_trades.count * 100).round(2) : 0,
          avg_profit: bot_trades.count > 0 ? (bot_trades.sum(&:profit) / bot_trades.count).round(2) : 0,
          max_profit: bot_trades.max_by(&:profit)&.profit || 0,
          max_loss: bot_trades.min_by(&:profit)&.profit || 0
        }
      end
      
      stats
    end
    
    def calculate_symbol_statistics(trades)
      stats = {}
      
      trades.group_by(&:symbol).each do |symbol, symbol_trades|
        stats[symbol] = {
          total_trades: symbol_trades.count,
          total_profit: symbol_trades.sum(&:profit),
          winning_trades: symbol_trades.count { |t| t.profit > 0 },
          losing_trades: symbol_trades.count { |t| t.profit < 0 },
          win_rate: symbol_trades.count > 0 ? (symbol_trades.count { |t| t.profit > 0 }.to_f / symbol_trades.count * 100).round(2) : 0,
          avg_profit: symbol_trades.count > 0 ? (symbol_trades.sum(&:profit) / symbol_trades.count).round(2) : 0
        }
      end
      
      stats
    end
    
    def bot_name_for_magic_number(magic_number, bots_cache)
      return "N/A" unless magic_number.present?
      
      magic_number_s = magic_number.to_s
      
      # Try to find an exact match first
      if bots_cache
        bot = bots_cache.find { |b| b.magic_number_prefix.to_s == magic_number_s }
        return bot.name if bot
      end
      
      # If not found by exact match, try partial match (prefix)
      if bots_cache
        bot = bots_cache.find { |b| b.magic_number_prefix.present? && magic_number_s.start_with?(b.magic_number_prefix.to_s) }
        return bot.name if bot
      end
      
      # Fallback if no bot is found
      "Bot #{magic_number}"
    end
  end
end
