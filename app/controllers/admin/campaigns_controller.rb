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

class Admin::CampaignsController < Admin::BaseController
  before_action :require_admin

  def index
    # Fallback to SQL if Campaign model not loaded
    begin
      @campaigns = Campaign.order(created_at: :desc)
    rescue => e
      Rails.logger.info "Campaign model not loaded, using SQL fallback: #{e.message}"
      campaigns_data = ActiveRecord::Base.connection.execute(
        "SELECT * FROM campaigns ORDER BY created_at DESC"
      )
      
      @campaigns = campaigns_data.map { |data| campaign_data_to_object(data) }
    end
  end

  def show
    begin
      @campaign = Campaign.find(params[:id])
    rescue => e
      Rails.logger.info "Campaign model not loaded, using SQL fallback: #{e.message}"
      campaign_data = ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([
          "SELECT * FROM campaigns WHERE id = ?",
          params[:id]
        ])
      ).first
      
      if campaign_data
        @campaign = campaign_data_to_object(campaign_data)
      else
        redirect_to admin_campaigns_path, alert: "Campagne non trouvée."
        return
      end
    end
  end

  def new
    @campaign = CampaignData.new(
      title: '',
      description: '',
      start_date: Time.current,
      end_date: 7.days.from_now,
      is_active: true,
      banner_color: '#3b82f6',
      popup_title: '',
      popup_message: ''
    )
  end

  def create
    # Create campaign using SQL
    title = params[:title]
    description = params[:description]
    start_date = params[:start_date]
    end_date = params[:end_date]
    is_active = params[:is_active] == '1'
    banner_color = params[:banner_color]
    popup_title = params[:popup_title]
    popup_message = params[:popup_message]
    
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "INSERT INTO campaigns (title, description, start_date, end_date, is_active, banner_color, popup_title, popup_message, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())",
        title, description, start_date, end_date, is_active, banner_color, popup_title, popup_message
      ])
    )
    
    redirect_to admin_campaigns_path, notice: 'Campagne créée avec succès.'
  end

  def edit
    begin
      @campaign = Campaign.find(params[:id])
    rescue => e
      Rails.logger.info "Campaign model not loaded, using SQL fallback: #{e.message}"
      campaign_data = ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([
          "SELECT * FROM campaigns WHERE id = ?",
          params[:id]
        ])
      ).first
      
      if campaign_data
        @campaign = campaign_data_to_object(campaign_data)
      else
        redirect_to admin_campaigns_path, alert: "Campagne non trouvée."
        return
      end
    end
  end

  def update
    # Update campaign using SQL
    title = params[:title]
    description = params[:description]
    start_date = params[:start_date]
    end_date = params[:end_date]
    is_active = params[:is_active] == '1'
    banner_color = params[:banner_color]
    popup_title = params[:popup_title]
    popup_message = params[:popup_message]
    
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "UPDATE campaigns SET title=?, description=?, start_date=?, end_date=?, is_active=?, banner_color=?, popup_title=?, popup_message=?, updated_at=NOW() WHERE id=?",
        title, description, start_date, end_date, is_active, banner_color, popup_title, popup_message, params[:id]
      ])
    )
    
    redirect_to admin_campaigns_path, notice: 'Campagne mise à jour avec succès.'
  end

  def destroy
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "DELETE FROM campaigns WHERE id = ?",
        params[:id]
      ])
    )
    redirect_to admin_campaigns_path, notice: 'Campagne supprimée avec succès.'
  end

  def toggle_active
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([
        "UPDATE campaigns SET is_active = NOT is_active, updated_at = NOW() WHERE id = ?",
        params[:id]
      ])
    )
    redirect_to admin_campaigns_path, notice: "Campagne mise à jour."
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
      created_at: parse_time_safe(data['created_at']),
      updated_at: parse_time_safe(data['updated_at'])
    )
  end

  def parse_time_safe(time_value)
    return nil if time_value.nil?
    return time_value if time_value.is_a?(Time)
    Time.parse(time_value.to_s)
  rescue
    nil
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :start_date, :end_date, :is_active, :banner_color, :popup_title, :popup_message)
  end
end
