class Vps < ApplicationRecord
  belongs_to :user
  
  before_save :set_renewal_date_if_needed
  after_save :update_renewal_date_from_first_trade
  
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
  
  def first_trade_date
    return nil unless user
    
    first_trade = Trade.joins(mt5_account: :user)
                      .where(users: { id: user_id })
                      .where(mt5_accounts: { is_admin_account: false })
                      .order(:open_time)
                      .first
    
    first_trade&.open_time&.to_date
  end
  
  def calculate_renewal_date
    first_trade = first_trade_date
    
    if first_trade
      # La date de renouvellement est un an après le premier trade
      first_trade + 1.year
    elsif ordered_at
      # Si pas de trade encore, utiliser la date de commande + 1 an
      ordered_at.to_date + 1.year
    end
  end
  
  private
  
  def set_renewal_date_if_needed
    # Si pas de date de renouvellement définie, la calculer
    if renewal_date.nil?
      self.renewal_date = calculate_renewal_date
    end
    
    # Prix par défaut si pas défini
    if monthly_price.nil? || monthly_price == 0
      self.monthly_price = 399.99
    end
  end
  
  def update_renewal_date_from_first_trade
    # Mettre à jour la date de renouvellement si le premier trade est plus récent que la date actuelle
    first_trade = first_trade_date
    
    if first_trade && renewal_date.nil?
      new_renewal_date = calculate_renewal_date
      update_column(:renewal_date, new_renewal_date) if new_renewal_date
    end
  end
end

