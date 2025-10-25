class BonusPeriod < ApplicationRecord
  belongs_to :campaign, optional: true
  
  validates :bonus_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :no_overlapping_active_periods

  scope :active, -> { where(active: true) }
  scope :current, -> { 
    active.where("start_date <= ? AND end_date >= ?", Date.current, Date.current)
          .order(created_at: :desc)
          .limit(1) 
  }

  def self.current_bonus_percentage
    current_period = current.first
    current_period&.bonus_percentage || 0.0
  end

  def current?
    active && start_date <= Date.current && end_date >= Date.current
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    
    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def no_overlapping_active_periods
    return unless active && start_date.present? && end_date.present?
    
    overlapping = BonusPeriod.active
                             .where.not(id: id)
                             .where("(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?)", 
                                    end_date, start_date, start_date, end_date)
    
    if overlapping.exists?
      errors.add(:base, "An active bonus period already exists for these dates")
    end
  end
end

