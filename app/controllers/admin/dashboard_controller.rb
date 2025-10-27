require 'ostruct'

# Simple Campaign class for when the model is not loaded
class CampaignData
  attr_accessor :id, :title, :description, :start_date, :end_date, :is_active, 
                :banner_color, :popup_title, :popup_message, :button_text, :button_url, :created_at, :updated_at, :errors

  def initialize(data = {})
    @errors = []
    data.each { |key, value| send("#{key}=", value) }
  end

  def active_and_current?
    is_active && Time.current <= end_date
  end

  def days_remaining
    return 0 unless active_and_current?
    
    now = Date.current
    end_date_val = end_date.to_date
    
    # Si la campagne n'a pas encore commencé, retourner les jours jusqu'au début
    if now < start_date.to_date
      return (start_date.to_date - now).to_i
    end
    
    # Sinon, retourner les jours jusqu'à la fin
    [(end_date_val - now).to_i, 0].max
  end

  def progress_percentage
    return 0 unless active_and_current?
    
    now = Date.current
    start = start_date.to_date
    end_date_val = end_date.to_date
    
    # Si la campagne n'a pas encore commencé
    if now < start
      return 0
    end
    
    # Si la campagne est terminée
    if now >= end_date_val
      return 100
    end
    
    # Calculer la progression normale
    total_days = (end_date_val - start).to_i
    elapsed_days = (now - start).to_i
    
    return 0 if total_days <= 0
    
    [(elapsed_days.to_f / total_days * 100).round, 100].min
  end

  def has_button?
    button_text.present? && button_url.present?
  end

  def persisted?
    !id.nil?
  end
end

module Admin
  class DashboardController < BaseController
    def index
      # Récupérer les paramètres de filtres
      @period = params[:period] || '30_days'
      @bot_filter = params[:bot_filter]
      @data_type = params[:data_type] || 'all'
      @chart_type = params[:chart_type] || 'combined'
      
      # Calculer les dates selon la période sélectionnée
      @date_range = calculate_date_range(@period)
      
      # Debug
      puts "=== DASHBOARD FILTERS DEBUG ==="
      puts "Period: #{@period}"
      puts "Bot filter: #{@bot_filter}"
      puts "Data type: #{@data_type}"
      puts "Chart type: #{@chart_type}"
      puts "Date range: #{@date_range}"
      puts "==============================="
      
      puts "=== DASHBOARD CONTROLLER CALLED ==="
      Rails.logger.info "=== DASHBOARD CONTROLLER CALLED ==="
      
      # Get current active campaign - fallback to SQL if model not loaded
      begin
        @current_campaign = Campaign.active_current.first
        puts "Campaign found via ActiveRecord: #{@current_campaign&.title}"
 "Campaign found via ActiveRecord: #{@current_campaign&.title}"
      rescue => e
        # Fallback: direct SQL query
 "Campaign model not loaded, using SQL fallback: #{e.message}"
        puts "Campaign model not loaded, using SQL fallback: #{e.message}"
        campaign_data = ActiveRecord::Base.connection.execute(
          "SELECT * FROM campaigns WHERE is_active = true AND end_date >= NOW() LIMIT 1"
        ).first
        
        if campaign_data
          @current_campaign = campaign_data_to_object(campaign_data)
 "=== CAMPAIGN DATA DEBUG ==="
 "Raw campaign data: #{campaign_data.inspect}"
 "Parsed campaign: #{@current_campaign.inspect}"
 "Is active: #{@current_campaign.is_active}"
 "Start date: #{@current_campaign.start_date}"
 "End date: #{@current_campaign.end_date}"
 "Current time: #{Time.current}"
 "Active and current: #{@current_campaign.active_and_current?}"
 "=========================="
        end
      end
      
      # Debug: Log campaign info
      Rails.logger.info "=== CAMPAIGN DEBUG ==="
      Rails.logger.info "All campaigns: #{Campaign.count rescue 'Model not loaded'}"
      Rails.logger.info "Active campaigns: #{Campaign.active.count rescue 'Model not loaded'}"
      Rails.logger.info "Current campaigns: #{Campaign.current.count rescue 'Model not loaded'}"
      Rails.logger.info "Active current campaigns: #{Campaign.active_current.count rescue 'Model not loaded'}"
      Rails.logger.info "Current campaign: #{@current_campaign&.title}"
      Rails.logger.info "======================"
      
      # Prédictions des bots pour les 2 prochains jours - VERSION ULTRA SIMPLE
      puts "=== CRÉATION ULTRA SIMPLE DES PRÉDICTIONS ==="
      
      # Créer un hash simple au lieu d'OpenStruct
      fake_bot = { name: "Bot Simple", id: 1 }
      
      begin
        @bot_predictions = [{
          bot: fake_bot,
          trading_hours: [
            { hour: 22, count: 1, percentage: 33.3 },
            { hour: 23, count: 1, percentage: 33.3 }
          ],
          trading_days: [
            { day: 6, day_name: 'Samedi', count: 2, percentage: 66.7 }
          ],
          predictions: [
            {
              date: Date.current,
              day_name: 'Dimanche',
              hour: 22,
              confidence: 50.0,
              probability: 0.33
            }
          ],
          total_trades: 3,
          success_rate: 66.7
        }]
        
        puts "@bot_predictions créé avec succès: #{@bot_predictions.count}"
        puts "@bot_predictions.first: #{@bot_predictions.first.inspect}"
      rescue => e
        puts "ERREUR lors de la création des prédictions: #{e.message}"
        @bot_predictions = []
      end
      
      if current_user.is_admin?
        # Admin dashboard with campaign
        @client = current_user
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        
        # Trades en cours (trades ouverts)
        @active_trades = Trade.joins(mt5_account: :user)
                             .where(status: 'open')
                             .includes(mt5_account: :user)
                             .order(open_time: :desc)
        
        # Prédictions déjà créées au-dessus
        
        # Debug
 "=== DASHBOARD DEBUG ==="
 "TradingBot.count: #{TradingBot.count}"
 "Trade.count: #{Trade.count}"
 "@bot_predictions.count: #{@bot_predictions.count}"
 "======================="
        
        # Statistiques globales
        @total_active_trades = @active_trades.count
        @total_active_users = User.joins(:trades).where(trades: { status: 'open' }).distinct.count
        
        # Statistics for charts
        @monthly_profits = calculate_monthly_profits
        @projection_data = calculate_projection
      else
        @client = current_user
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        
        # Trades en cours pour ce client
        @active_trades = @client.trades.where(status: 'open').order(open_time: :desc)
        
        # Prédictions des bots pour ce client
        @bot_predictions = calculate_client_bot_predictions(@client)
        
        # Statistics for charts
        @monthly_profits = calculate_monthly_profits
        @projection_data = calculate_projection
    end
  end

  def monitoring_status
    all_accounts = Mt5Account.all
    online_accounts = all_accounts.where("last_heartbeat_at > ?", 30.seconds.ago)
    offline_accounts = all_accounts.where("last_heartbeat_at <= ? OR last_heartbeat_at IS NULL", 30.seconds.ago)
    
    render json: {
      online_count: online_accounts.count,
      offline_count: offline_accounts.count,
      offline_accounts: offline_accounts.map do |account|
        {
          account_name: account.account_name,
          last_heartbeat_at: account.last_heartbeat_at,
          time_ago: account.last_heartbeat_at ? time_ago_in_words(account.last_heartbeat_at) : nil
        }
      end
    }
  end

  def test_icons
    # Page de test pour les icônes
    render 'admin/test_icons'
  end

  def test_dropdowns
    # Page de test pour les dropdowns
    render 'admin/test_dropdowns'
  end

  def test_dashboard_dropdowns
    # Page de test pour les dropdowns du dashboard
    render 'admin/test_dashboard_dropdowns'
  end

  def test_client_dropdowns
    # Page de test pour les dropdowns de la page client
    render 'admin/test_client_dropdowns'
  end

  def routes_test
    # Page de test pour vérifier que les routes fonctionnent
    render 'admin/routes_test'
  end

  private

  def calculate_date_range(period)
    case period
    when '7_days'
      { from: 7.days.ago, to: Time.current }
    when '30_days'
      { from: 30.days.ago, to: Time.current }
    when '3_months'
      { from: 3.months.ago, to: Time.current }
    when '6_months'
      { from: 6.months.ago, to: Time.current }
    when '1_year'
      { from: 1.year.ago, to: Time.current }
    else
      { from: 1.year.ago, to: Time.current }
    end
  end

    def campaign_data_to_object(data)
      CampaignData.new(
        id: data['id'].to_i,
        title: data['title'],
        description: data['description'],
        start_date: parse_time_safe(data['start_date']),
        end_date: parse_time_safe(data['end_date']),
        is_active: data['is_active'] == 't' || data['is_active'] == true,
        banner_color: data['banner_color'],
        popup_title: data['popup_title'],
        popup_message: data['popup_message'],
        button_text: data['button_text'],
        button_url: data['button_url']
      )
    end

    def parse_time_safe(time_value)
      return nil if time_value.nil?
      return time_value if time_value.is_a?(Time)
      Time.parse(time_value.to_s)
    rescue
      nil
    end

    def calculate_monthly_profits
      trades_by_month = current_user.trades
                                    .where('close_time >= ?', 12.months.ago)
                                    .group_by { |t| t.close_time.beginning_of_month }
      
      (0..11).map do |i|
        month = i.months.ago.beginning_of_month
        month_profit = trades_by_month[month]&.sum(&:profit) || 0
        {
          month: month.strftime('%b %Y'),
          profit: month_profit.round(2)
        }
      end.reverse
    end

    def calculate_projection
      current_balance = current_user.mt5_accounts.sum(:balance)
      
      recent_trades = current_user.trades.where('close_time >= ?', 6.months.ago)
      
      if recent_trades.empty?
        monthly_avg_profit = 50.0
      else
        total_profit = recent_trades.sum(:profit)
        months_with_trades = recent_trades.group_by { |t| t.close_time.beginning_of_month }.count
        months_with_trades = [months_with_trades, 1].max
        monthly_avg_profit = total_profit / months_with_trades
      end
      
      running_balance = current_balance
      
      (1..6).map do |i|
        month = i.months.from_now.beginning_of_month
        running_balance += monthly_avg_profit
        {
          month: month.strftime('%b %Y'),
          balance: running_balance.round(2)
        }
      end
    end

    # Calculer les prédictions des bots pour les 2 prochains jours (vue admin)
    def calculate_bot_predictions
      # Version ULTRA SIMPLE - toujours retourner des données
      puts "=== CALCULATE_BOT_PREDICTIONS ULTRA SIMPLE ==="
      
      # Créer un bot fictif pour tester
      fake_bot = OpenStruct.new(name: "Bot Test", id: 1)
      
      predictions = [{
        bot: fake_bot,
        trading_hours: [
          { hour: 22, count: 1, percentage: 33.3 },
          { hour: 23, count: 1, percentage: 33.3 },
          { hour: 0, count: 1, percentage: 33.3 }
        ],
        trading_days: [
          { day: 6, day_name: 'Samedi', count: 2, percentage: 66.7 },
          { day: 0, day_name: 'Dimanche', count: 1, percentage: 33.3 }
        ],
        predictions: [
          {
            date: Date.current,
            day_name: 'Dimanche',
            hour: 22,
            confidence: 50.0,
            probability: 0.33
          },
          {
            date: Date.current,
            day_name: 'Dimanche', 
            hour: 23,
            confidence: 50.0,
            probability: 0.33
          }
        ],
        total_trades: 3,
        success_rate: 66.7
      }]
      
      puts "Ultra simple prediction created: #{predictions.count} predictions"
      puts "=== END CALCULATE_BOT_PREDICTIONS ULTRA SIMPLE ==="
      
      predictions
    end

    # Calculer les prédictions pour un client spécifique
    def calculate_client_bot_predictions(client)
      predictions = []
      
      # Récupérer les bots assignés à ce client
      client.bot_purchases.includes(:trading_bot).each do |purchase|
        bot = purchase.trading_bot
        next unless bot.magic_number_prefix.present?
        
        # Récupérer les trades de ce bot pour ce client
        bot_trades = client.trades.where(magic_number: bot.magic_number_prefix)
                          .where('close_time >= ?', 30.days.ago)
        
        next if bot_trades.empty?
        
        # Analyser les patterns
        trading_hours = analyze_trading_hours(bot_trades)
        trading_days = analyze_trading_days(bot_trades)
        
        # Générer les prédictions pour aujourd'hui seulement
        today_predictions = generate_today_predictions(trading_hours, trading_days)
        
        predictions << {
          bot: bot,
          purchase: purchase,
          trading_hours: trading_hours,
          trading_days: trading_days,
          predictions: today_predictions,
          total_trades: bot_trades.count,
          success_rate: calculate_success_rate(bot_trades)
        }
      end
      
      predictions.sort_by { |p| -p[:total_trades] }
    end

    # Analyser les heures de trading optimales
    def analyze_trading_hours(trades)
      hour_stats = trades.group_by { |t| t.close_time.hour }
                        .transform_values(&:count)
                        .sort_by { |hour, count| -count }
                        .first(5) # Top 5 heures
      
      hour_stats.map do |hour, count|
        {
          hour: hour,
          count: count,
          percentage: (count.to_f / trades.count * 100).round(1)
        }
      end
    end

    # Analyser les jours de trading optimaux
    def analyze_trading_days(trades)
      weekday_names = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi']
      
      day_stats = trades.group_by { |t| t.close_time.wday }
                       .transform_values(&:count)
                       .sort_by { |day, count| -count }
                       .first(3) # Top 3 jours
      
      day_stats.map do |wday, count|
        {
          day: wday,
          day_name: weekday_names[wday],
          count: count,
          percentage: (count.to_f / trades.count * 100).round(1)
        }
      end
    end

    # Générer les prédictions pour aujourd'hui seulement
    def generate_today_predictions(trading_hours, trading_days)
      predictions = []
      
      # Aujourd'hui seulement
      today = Date.current
      today_wday = today.wday
      
      # Vérifier si aujourd'hui est dans les jours optimaux
      optimal_day = trading_days.find { |d| d[:day] == today_wday }
      
      if optimal_day
        # Ce jour est optimal, prédire les heures optimales
        optimal_hours = trading_hours.select { |h| h[:percentage] >= 10 } # Heures avec au moins 10% des trades
        
        optimal_hours.each do |hour_data|
          predictions << {
            date: today,
            day_name: optimal_day[:day_name],
            hour: hour_data[:hour],
            confidence: (optimal_day[:percentage] + hour_data[:percentage]) / 2,
            probability: calculate_trading_probability(optimal_day, hour_data)
          }
        end
      end
      
      predictions.sort_by { |p| p[:hour] }
    end

    # Calculer la probabilité de trading
    def calculate_trading_probability(day_data, hour_data)
      base_probability = (day_data[:percentage] + hour_data[:percentage]) / 200.0
      
      # Ajuster selon l'heure (les heures de marché sont plus probables)
      market_hours = [9, 10, 11, 14, 15, 16, 17, 18, 19, 20, 21, 22]
      if market_hours.include?(hour_data[:hour])
        base_probability *= 1.2
      end
      
      [base_probability, 1.0].min.round(2)
    end

    # Calculer le taux de réussite
    def calculate_success_rate(trades)
      return 0 if trades.empty?
      
      winning_trades = trades.where('profit > 0').count
      (winning_trades.to_f / trades.count * 100).round(1)
    end
  end
end

