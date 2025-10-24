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
      puts "=== DASHBOARD CONTROLLER CALLED ==="
      Rails.logger.info "=== DASHBOARD CONTROLLER CALLED ==="
      
      # Get current active campaign - fallback to SQL if model not loaded
      begin
        @current_campaign = Campaign.active_current.first
        puts "Campaign found via ActiveRecord: #{@current_campaign&.title}"
        Rails.logger.info "Campaign found via ActiveRecord: #{@current_campaign&.title}"
      rescue => e
        # Fallback: direct SQL query
        Rails.logger.info "Campaign model not loaded, using SQL fallback: #{e.message}"
        puts "Campaign model not loaded, using SQL fallback: #{e.message}"
        campaign_data = ActiveRecord::Base.connection.execute(
          "SELECT * FROM campaigns WHERE is_active = true AND end_date >= NOW() LIMIT 1"
        ).first
        
        if campaign_data
          @current_campaign = campaign_data_to_object(campaign_data)
          Rails.logger.info "=== CAMPAIGN DATA DEBUG ==="
          Rails.logger.info "Raw campaign data: #{campaign_data.inspect}"
          Rails.logger.info "Parsed campaign: #{@current_campaign.inspect}"
          Rails.logger.info "Is active: #{@current_campaign.is_active}"
          Rails.logger.info "Start date: #{@current_campaign.start_date}"
          Rails.logger.info "End date: #{@current_campaign.end_date}"
          Rails.logger.info "Current time: #{Time.current}"
          Rails.logger.info "Active and current: #{@current_campaign.active_and_current?}"
          Rails.logger.info "=========================="
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
      
      if current_user.is_admin?
        # Admin dashboard with campaign
        @client = current_user
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        
        # Statistics for charts
        @monthly_profits = calculate_monthly_profits
        @projection_data = calculate_projection
      else
        @client = current_user
        @mt5_accounts = @client.mt5_accounts.includes(:trades, :withdrawals)
        
        # Statistics for charts
        @monthly_profits = calculate_monthly_profits
        @projection_data = calculate_projection
      end
    end

    private

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
  end
end

