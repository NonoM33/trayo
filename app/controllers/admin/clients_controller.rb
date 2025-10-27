module Admin
  class ClientsController < BaseController
    before_action :require_admin, except: [:show, :edit, :update, :test_dropdowns, :debug]
    before_action :ensure_own_profile_or_admin, only: [:show, :edit, :update]
    
    def index
      @clients = User.clients.order(:email)
      @admins = User.admins.order(:email)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_create_params)
      if @user.save
        redirect_to admin_clients_path, notice: "User created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @client = User.find(params[:id])
      @client.reload
      @mt5_accounts = @client.mt5_accounts.reload.includes(:trades, :withdrawals)
      @payments = @client.payments.recent
      @credits = @client.credits.recent
      
      bot_purchases_count = @client.bot_purchases.count
      Rails.logger.debug "Client show - Bot purchases count: #{bot_purchases_count}"
      Rails.logger.debug "Client show - Bot purchases: #{@client.bot_purchases.pluck(:id, :purchase_type, :created_at).inspect}"
      
      # Précharger les bots pour optimiser les performances
      @bots_cache = TradingBot.where.not(magic_number_prefix: nil)
    end

    def test_dropdowns
      # Page de test pour les dropdowns de la page client
      render 'admin/test_client_dropdowns'
    end

    def debug
      # Page de debug pour l'accès aux clients
      render 'admin/client_access_debug'
    end

    def edit
      @client = User.find(params[:id])
    end

    def update
      @client = User.find(params[:id])
      
      update_params = if current_user.is_admin?
        user_update_params
      else
        user_update_params.except(:is_admin, :commission_rate)
      end
      
      if @client.update(update_params)
        redirect_to admin_client_path(@client), notice: "User updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reset_password
      @client = User.find(params[:id])
      new_password = params[:new_password].presence || SecureRandom.alphanumeric(12)
      
      if @client.update(password: new_password, password_confirmation: new_password)
        if params[:send_email]
          flash[:notice] = "Password reset successfully. Email sent to #{@client.email} with new password: #{new_password}"
        else
          flash[:notice] = "Password reset successfully. New password: #{new_password}"
        end
      else
        flash[:alert] = "Failed to reset password"
      end
      
      redirect_to edit_admin_client_path(@client)
    end

    def regenerate_token
      @client = User.find(params[:id])
      @client.update(mt5_api_token: SecureRandom.hex(32))
      redirect_to edit_admin_client_path(@client), notice: "API token regenerated successfully"
    end

    def trades
      @client = User.find(params[:id])
      
      # Récupérer tous les trades de tous les comptes MT5 du client
      @trades = Trade.joins(:mt5_account)
                    .where(mt5_accounts: { user_id: @client.id })
                    .includes(:mt5_account)
                    .order(close_time: :desc)
      
      # Précharger les bots pour optimiser les performances
      @bots_cache = TradingBot.where.not(magic_number_prefix: nil)
      
      # Filtres
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
      
      # Pagination
      @trades = @trades.page(params[:page]).per(50)
      
      # Statistiques
      @total_trades = @trades.total_count
      @total_profit = @trades.sum(:profit)
      @winning_trades = @trades.where('profit > 0').count
      @losing_trades = @trades.where('profit < 0').count
      @win_rate = @total_trades > 0 ? (@winning_trades.to_f / @total_trades * 100).round(2) : 0
      
      # Options pour les filtres
      @symbols = Trade.joins(:mt5_account)
                     .where(mt5_accounts: { user_id: @client.id })
                     .distinct.pluck(:symbol).compact.sort
      
      @magic_numbers = Trade.joins(:mt5_account)
                           .where(mt5_accounts: { user_id: @client.id })
                           .distinct.pluck(:magic_number).compact.sort
    end

    def bots
      @client = User.find(params[:id])
      
      # Récupérer tous les trades du client
      @trades = Trade.joins(:mt5_account)
                    .where(mt5_accounts: { user_id: @client.id })
                    .includes(:mt5_account)
                    .order(close_time: :desc)
      
      # Précharger les bots
      @bots_cache = TradingBot.where.not(magic_number_prefix: nil)
      
      # Analyser les performances par bot
      @bot_performances = analyze_bot_performances(@trades, @bots_cache)
      
      # Analyser les jours de trading
      @trading_days_analysis = analyze_trading_days(@trades)
      
      # Statistiques globales
      @total_trades = @trades.count
      @total_profit = @trades.sum(:profit)
      @winning_trades = @trades.where('profit > 0').count
      @losing_trades = @trades.where('profit < 0').count
      @win_rate = @total_trades > 0 ? (@winning_trades.to_f / @total_trades * 100).round(2) : 0
    end

    def destroy
      @user = User.find(params[:id])
      if @user.id == current_user.id
        redirect_to admin_clients_path, alert: "You cannot delete yourself"
        return
      end
      
      @user.destroy
      redirect_to admin_clients_path, notice: "User deleted successfully"
    end

    def auto_detect_bots
      @client = User.find(params[:id])
      
      old_bot_count = @client.bot_purchases.count
      
      # Solution de contournement : utiliser SQL direct au lieu de la méthode Ruby
      # qui ne fonctionne pas à cause des problèmes de Bundler
      
      # Récupérer tous les magic numbers uniques des trades de l'utilisateur
      magic_numbers = Trade.joins(mt5_account: :user)
                          .where(users: { id: @client.id })
                          .distinct
                          .pluck(:magic_number)
                          .compact
      
      bots_assigned = 0
      
      magic_numbers.each do |magic_number|
        # Chercher un bot qui correspond à ce magic number
        bot = TradingBot.find_by(magic_number_prefix: magic_number)
        
        if bot && !@client.bot_purchases.exists?(trading_bot: bot)
          # Créer automatiquement un BotPurchase pour ce bot
          @client.bot_purchases.create!(
            trading_bot: bot,
            price_paid: bot.price,
            status: 'active',
            magic_number: magic_number,
            is_running: true,
            started_at: Time.current,
            purchase_type: 'auto_detected'
          )
          bots_assigned += 1
        end
      end
      
      if bots_assigned > 0
        redirect_to admin_client_path(@client), notice: "#{bots_assigned} bot(s) détecté(s) et assigné(s) automatiquement !"
      else
        redirect_to admin_client_path(@client), notice: "Aucun nouveau bot détecté. Tous les bots correspondants sont déjà assignés."
      end
    end

    private

    def analyze_bot_performances(trades, bots_cache)
      performances = {}
      
      # Grouper les trades par magic number
      trades_by_magic = trades.group_by(&:magic_number)
      
      trades_by_magic.each do |magic_number, bot_trades|
        next if magic_number.blank?
        
        # Trouver le bot correspondant
        bot = bots_cache.find { |b| b.magic_number_prefix == magic_number }
        bot_name = bot ? bot.name : "Bot #{magic_number}"
        
        # Calculer les statistiques
        total_profit = bot_trades.sum(&:profit)
        winning_trades = bot_trades.count { |t| t.profit > 0 }
        losing_trades = bot_trades.count { |t| t.profit < 0 }
        win_rate = bot_trades.count > 0 ? (winning_trades.to_f / bot_trades.count * 100).round(2) : 0
        
        # Calculer le drawdown en pourcentage
        drawdown_percentage = calculate_drawdown_percentage(bot_trades, bot)
        
        # Calculer le profit moyen
        avg_profit = bot_trades.count > 0 ? (total_profit / bot_trades.count).round(2) : 0
        
        # Analyser les heures de trading
        trading_hours = analyze_trading_hours(bot_trades)
        
        # Analyser les jours de la semaine
        trading_weekdays = analyze_trading_weekdays(bot_trades)
        
        performances[bot_name] = {
          magic_number: magic_number,
          total_trades: bot_trades.count,
          total_profit: total_profit,
          winning_trades: winning_trades,
          losing_trades: losing_trades,
          win_rate: win_rate,
          drawdown_percentage: drawdown_percentage,
          avg_profit: avg_profit,
          trading_hours: trading_hours,
          trading_weekdays: trading_weekdays,
          trades: bot_trades
        }
      end
      
      performances
    end

    def analyze_trading_days(trades)
      # Analyser les jours de la semaine
      weekday_stats = trades.group_by { |t| t.close_time&.wday }
                           .transform_values(&:count)
      
      # Analyser les heures de trading
      hour_stats = trades.group_by { |t| t.close_time&.hour }
                        .transform_values(&:count)
      
      {
        weekdays: weekday_stats,
        hours: hour_stats,
        best_weekday: weekday_stats.max_by { |k, v| v }&.first,
        best_hour: hour_stats.max_by { |k, v| v }&.first
      }
    end

    def calculate_drawdown_percentage(trades, bot)
      return 0 if trades.empty? || bot.max_drawdown_limit.zero?
      
      # Trier les trades par close_time pour avoir l'ordre chronologique
      sorted_trades = trades.sort_by { |t| t.close_time || t.open_time || Time.current }
      
      running_balance = 0
      peak_balance = 0
      max_drawdown = 0
      
      sorted_trades.each do |trade|
        running_balance += trade.profit
        peak_balance = [peak_balance, running_balance].max
        current_drawdown = peak_balance - running_balance
        max_drawdown = [max_drawdown, current_drawdown].max
      end
      
      # Convertir le drawdown en pourcentage par rapport à la limite
      drawdown_percentage = (max_drawdown / bot.max_drawdown_limit * 100).round(2)
      
      Rails.logger.info "=== DRAWDOWN PERCENTAGE CALCULATION ==="
      Rails.logger.info "Total trades: #{trades.count}"
      Rails.logger.info "Max drawdown (€): #{max_drawdown.round(2)}"
      Rails.logger.info "Bot drawdown limit (€): #{bot.max_drawdown_limit}"
      Rails.logger.info "Drawdown percentage: #{drawdown_percentage}%"
      Rails.logger.info "====================================="
      
      drawdown_percentage
    end

    def calculate_drawdown(trades)
      return 0 if trades.empty?
      
      # Trier les trades par close_time pour avoir l'ordre chronologique
      sorted_trades = trades.sort_by { |t| t.close_time || t.open_time || Time.current }
      
      running_balance = 0
      peak_balance = 0
      max_drawdown = 0
      
      sorted_trades.each do |trade|
        running_balance += trade.profit
        peak_balance = [peak_balance, running_balance].max
        current_drawdown = peak_balance - running_balance
        max_drawdown = [max_drawdown, current_drawdown].max
        
        # Debug log pour tracer le calcul
        Rails.logger.info "Trade #{trade.id}: profit=#{trade.profit}, running_balance=#{running_balance}, peak_balance=#{peak_balance}, current_drawdown=#{current_drawdown}, max_drawdown=#{max_drawdown}"
      end
      
      Rails.logger.info "=== DRAWDOWN CALCULATION RESULT ==="
      Rails.logger.info "Total trades: #{trades.count}"
      Rails.logger.info "Final running_balance: #{running_balance}"
      Rails.logger.info "Final peak_balance: #{peak_balance}"
      Rails.logger.info "Final max_drawdown: #{max_drawdown}"
      Rails.logger.info "================================"
      
      max_drawdown.round(2)
    end

    def analyze_trading_hours(trades)
      hour_stats = trades.group_by { |t| t.close_time&.hour }
                        .transform_values(&:count)
      
      hour_stats.sort_by { |k, v| -v }.first(3)
    end

    def analyze_trading_weekdays(trades)
      weekday_names = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
      
      weekday_stats = trades.group_by { |t| t.close_time&.wday }
                           .transform_values(&:count)
      
      weekday_stats.map { |wday, count| [weekday_names[wday], count] }
                  .sort_by { |k, v| -v }
                  .first(3)
    end

    def user_create_params
      params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :commission_rate, :is_admin)
    end

    def user_update_params
      params.require(:user).permit(:email, :first_name, :last_name, :phone, :commission_rate, :is_admin)
    end

    def ensure_own_profile_or_admin
      @client = User.find(params[:id])
      unless current_user.is_admin? || current_user.id == @client.id
        redirect_to admin_client_path(current_user), alert: "You can only view your own profile"
      end
    end
  end
end

