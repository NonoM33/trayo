class Campaign < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :banner_color, presence: true
  validates :popup_title, presence: true
  validates :popup_message, presence: true
  
  validate :end_date_after_start_date
  validate :button_url_format, if: -> { button_url.present? }
  
  scope :active, -> { where(is_active: true) }
  scope :current, -> { where('end_date >= ?', Time.current) }
  scope :active_current, -> { active.current }
  
  def current?
    Time.current <= end_date
  end
  
  def active_and_current?
    is_active? && current?
  end
  
  def days_remaining
    return 0 unless current?
    
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
    return 0 unless current?
    
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
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date <= start_date
      errors.add(:end_date, 'doit être après la date de début')
    end
  end
  
  def button_url_format
    return unless button_url.present?
    
    begin
      uri = URI.parse(button_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:button_url, 'doit être une URL valide (http:// ou https://)')
      end
    rescue URI::InvalidURIError
      errors.add(:button_url, 'doit être une URL valide')
    end
  end
end
