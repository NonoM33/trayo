module Admin
  class TradesController < BaseController
    before_action :require_admin

    def index
      # Récupérer tous les trades de tous les clients
      @trades = Trade.joins(mt5_account: :user)
                    .includes(:mt5_account, mt5_account: :user)
                    .order(close_time: :desc)
      
      # Précharger les bots pour optimiser les performances
      @bots_cache = TradingBot.where.not(magic_number_prefix: nil)
      
      # Filtres
      if params[:client_id].present?
        @trades = @trades.where(mt5_accounts: { user_id: params[:client_id] })
      end
      
      if params[:symbol].present?
        @trades = @trades.where(symbol: params[:symbol])
      end
      
      if params[:magic_number].present?
        @trades = @trades.where(magic_number: params[:magic_number])
      end
      
      if params[:date_from].present?
        @trades = @trades.where('close_time >= ?', Date.parse(params[:date_from]).beginning_of_day)
      end
      
      if params[:date_to].present?
        @trades = @trades.where('close_time <= ?', Date.parse(params[:date_to]).end_of_day)
      end
      
      if params[:profit_filter].present?
        case params[:profit_filter]
        when 'positive'
          @trades = @trades.where('profit > 0')
        when 'negative'
          @trades = @trades.where('profit < 0')
        when 'zero'
          @trades = @trades.where(profit: 0)
        end
      end
      
      # Statistiques globales (calculées AVANT pagination)
      @total_trades = @trades.count
      @total_profit = @trades.sum(:profit)
      @winning_trades = @trades.where('profit > 0').count
      @losing_trades = @trades.where('profit < 0').count
      @win_rate = @total_trades > 0 ? (@winning_trades.to_f / @total_trades * 100).round(2) : 0
      
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
      when 'client'
        @trades = @trades.joins(mt5_account: :user).order('users.first_name, users.last_name', close_time: :desc)
      else
        @trades = @trades.order(close_time: :desc)
      end
      
      # Pagination (après calcul des statistiques)
      @trades = @trades.page(params[:page]).per(100)
      
      # Options pour les filtres
      @clients = User.clients.order(:first_name, :last_name)
      @symbols = Trade.distinct.pluck(:symbol).compact.sort
      @magic_numbers = Trade.where.not(magic_number: nil).distinct.pluck(:magic_number).compact.sort
      
      # Statistiques par magic number
      @magic_stats = Trade.where.not(magic_number: nil)
                         .group(:magic_number)
                         .select('magic_number, COUNT(*) as trades_count, SUM(profit) as total_profit, AVG(profit) as avg_profit')
                         .order(:magic_number)
    end

    def show
      @trade = Trade.find(params[:id])
    end

    def export
      @trades = Trade.joins(mt5_account: :user)
                    .includes(:mt5_account, mt5_account: :user)
                    .order(close_time: :desc)
      
      # Appliquer les mêmes filtres que dans index
      if params[:client_id].present?
        @trades = @trades.where(mt5_accounts: { user_id: params[:client_id] })
      end
      
      if params[:symbol].present?
        @trades = @trades.where(symbol: params[:symbol])
      end
      
      if params[:magic_number].present?
        @trades = @trades.where(magic_number: params[:magic_number])
      end
      
      if params[:date_from].present?
        @trades = @trades.where('close_time >= ?', Date.parse(params[:date_from]).beginning_of_day)
      end
      
      if params[:date_to].present?
        @trades = @trades.where('close_time <= ?', Date.parse(params[:date_to]).end_of_day)
      end
      
      respond_to do |format|
        format.csv do
          send_data generate_csv(@trades), 
                    filename: "trades_#{Date.current.strftime('%Y%m%d')}.csv",
                    type: 'text/csv'
        end
      end
    end

    private

    def generate_csv(trades)
      require 'csv'
      
      CSV.generate do |csv|
        csv << [
          'Date Fermeture', 'Client', 'Compte MT5', 'Symbole', 'Type', 'Volume',
          'Prix Ouverture', 'Prix Fermeture', 'Profit', 'Commission', 'Swap',
          'Magic Number', 'Commentaire'
        ]
        
        trades.each do |trade|
          csv << [
            trade.close_time&.strftime('%Y-%m-%d %H:%M:%S'),
            "#{trade.mt5_account.user.first_name} #{trade.mt5_account.user.last_name}",
            trade.mt5_account.account_name,
            trade.symbol,
            trade.trade_type,
            trade.volume,
            trade.open_price,
            trade.close_price,
            trade.profit,
            trade.commission,
            trade.swap,
            trade.magic_number,
            trade.comment
          ]
        end
      end
    end
  end
end
