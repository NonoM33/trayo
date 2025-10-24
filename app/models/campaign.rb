class Campaign < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :banner_color, presence: true
  validates :popup_title, presence: true
  validates :popup_message, presence: true
  
  validate :end_date_after_start_date
  
  scope :active, -> { where(is_active: true) }
  scope :current, -> { where('start_date <= ? AND end_date >= ?', Time.current, Time.current) }
  scope :active_current, -> { active.current }
  
  def current?
    Time.current.between?(start_date, end_date)
  end
  
  def active_and_current?
    is_active? && current?
  end
  
  def days_remaining
    return 0 unless current?
    (end_date.to_date - Date.current).to_i
  end
  
  def progress_percentage
    return 0 unless current?
    total_days = (end_date.to_date - start_date.to_date).to_i
    elapsed_days = (Date.current - start_date.to_date).to_i
    [(elapsed_days.to_f / total_days * 100).round, 100].min
  end
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date <= start_date
      errors.add(:end_date, 'doit être après la date de début')
    end
  end
end
