class MaintenanceSetting < ApplicationRecord
  validates :title, presence: true, if: -> { is_enabled? }
  validates :subtitle, presence: true, if: -> { is_enabled? }
  validates :description, presence: true, if: -> { is_enabled? }
  
  validate :countdown_date_future, if: -> { countdown_date.present? }
  
  def self.current
    first || create!(is_enabled: false, title: "Maintenance", subtitle: "Site en maintenance", description: "Nous travaillons pour améliorer votre expérience.")
  end
  
  def self.enabled?
    current.is_enabled?
  end
  
  def countdown_remaining
    return nil unless countdown_date.present?
    
    remaining = countdown_date - Time.current
    return 0 if remaining <= 0
    
    remaining.to_i
  end
  
  def countdown_days
    return 0 unless countdown_remaining
    (countdown_remaining / 1.day).to_i
  end
  
  def countdown_hours
    return 0 unless countdown_remaining
    ((countdown_remaining % 1.day) / 1.hour).to_i
  end
  
  def countdown_minutes
    return 0 unless countdown_remaining
    ((countdown_remaining % 1.hour) / 1.minute).to_i
  end
  
  def countdown_seconds
    return 0 unless countdown_remaining
    (countdown_remaining % 1.minute).to_i
  end
  
  private
  
  def countdown_date_future
    return unless countdown_date.present?
    
    if countdown_date <= Time.current
      errors.add(:countdown_date, 'doit être dans le futur')
    end
  end
end
