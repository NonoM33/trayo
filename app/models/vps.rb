class Vps < ApplicationRecord
  belongs_to :user
  
  STATUSES = {
    'ordered' => 'Commandé',
    'configuring' => 'En Configuration',
    'ready' => 'Prêt',
    'active' => 'Actif',
    'suspended' => 'Suspendu',
    'cancelled' => 'Annulé'
  }.freeze
  
  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES.keys }
  validates :monthly_price, numericality: { greater_than_or_equal_to: 0 }
  
  scope :ordered, -> { where(status: 'ordered') }
  scope :configuring, -> { where(status: 'configuring') }
  scope :ready, -> { where(status: 'ready') }
  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
  
  def status_label
    STATUSES[status] || status
  end
  
  def status_color
    case status
    when 'ordered' then '#FF9800'
    when 'configuring' then '#2196F3'
    when 'ready' then '#4CAF50'
    when 'active' then '#00C853'
    when 'suspended' then '#F44336'
    when 'cancelled' then '#999'
    else '#666'
    end
  end
  
  def status_icon
    case status
    when 'ordered' then '🛒'
    when 'configuring' then '⚙️'
    when 'ready' then '✅'
    when 'active' then '🟢'
    when 'suspended' then '⏸️'
    when 'cancelled' then '🔴'
    else '⚪'
    end
  end
  
  def mark_as_configuring!
    update(status: 'configuring', configured_at: Time.current)
  end
  
  def mark_as_ready!
    update(status: 'ready', ready_at: Time.current)
  end
  
  def mark_as_active!
    update(status: 'active', activated_at: Time.current)
  end
  
  def suspend!
    update(status: 'suspended')
  end
  
  def cancel!
    update(status: 'cancelled')
  end
  
  def days_since_order
    return 0 unless ordered_at
    ((Time.current - ordered_at) / 1.day).round
  end
  
  def is_operational?
    %w[ready active].include?(status)
  end
end

