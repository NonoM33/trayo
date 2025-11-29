class Banner < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  has_many :banner_dismissals, dependent: :destroy

  TYPES = %w[info success warning error promotion announcement maintenance].freeze
  TARGET_AUDIENCES = %w[all active_clients inactive_clients with_balance unpaid_commissions new_clients specific_users].freeze

  validates :title, presence: true
  validates :banner_type, inclusion: { in: TYPES }
  validates :target_audience, inclusion: { in: TARGET_AUDIENCES }

  scope :active, -> { where(is_active: true) }
  scope :current, -> { 
    active
      .where('starts_at IS NULL OR starts_at <= ?', Time.current)
      .where('ends_at IS NULL OR ends_at >= ?', Time.current)
  }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }

  def active_now?
    is_active && 
    (starts_at.nil? || starts_at <= Time.current) &&
    (ends_at.nil? || ends_at >= Time.current)
  end

  def dismissed_by?(user)
    banner_dismissals.exists?(user: user)
  end

  def visible_for?(user)
    return false unless active_now?
    return false if is_dismissible && dismissed_by?(user)
    matches_audience?(user)
  end

  def matches_audience?(user)
    case target_audience
    when 'all'
      true
    when 'active_clients'
      user.bot_purchases.where(is_running: true).exists?
    when 'inactive_clients'
      !user.bot_purchases.where(is_running: true).exists?
    when 'with_balance'
      user.mt5_accounts.where('balance > 0').exists?
    when 'unpaid_commissions'
      user.commission_balance_due.to_f > 0
    when 'new_clients'
      user.created_at > 30.days.ago
    when 'specific_users'
      target_user_ids.include?(user.id)
    else
      true
    end
  end

  def target_user_ids
    return [] if target_filters.blank?
    JSON.parse(target_filters)['user_ids'] rescue []
  end

  def dismiss!(user)
    banner_dismissals.find_or_create_by(user: user) do |d|
      d.dismissed_at = Time.current
    end
    increment!(:dismissals_count)
  end

  def record_view!
    increment!(:views_count)
  end

  def record_click!
    increment!(:clicks_count)
  end

  def type_config
    {
      'info' => { icon: 'fa-info-circle', bg: 'from-blue-900/50 to-blue-800/30', border: 'border-blue-500/50', text: 'text-blue-400' },
      'success' => { icon: 'fa-check-circle', bg: 'from-emerald-900/50 to-emerald-800/30', border: 'border-emerald-500/50', text: 'text-emerald-400' },
      'warning' => { icon: 'fa-exclamation-triangle', bg: 'from-amber-900/50 to-amber-800/30', border: 'border-amber-500/50', text: 'text-amber-400' },
      'error' => { icon: 'fa-times-circle', bg: 'from-red-900/50 to-red-800/30', border: 'border-red-500/50', text: 'text-red-400' },
      'promotion' => { icon: 'fa-gift', bg: 'from-purple-900/50 to-pink-800/30', border: 'border-purple-500/50', text: 'text-purple-400' },
      'announcement' => { icon: 'fa-bullhorn', bg: 'from-cyan-900/50 to-teal-800/30', border: 'border-cyan-500/50', text: 'text-cyan-400' },
      'maintenance' => { icon: 'fa-tools', bg: 'from-orange-900/50 to-orange-800/30', border: 'border-orange-500/50', text: 'text-orange-400' }
    }[banner_type] || { icon: 'fa-info-circle', bg: 'from-neutral-800 to-neutral-700', border: 'border-neutral-600', text: 'text-neutral-400' }
  end

  def type_label
    {
      'info' => 'ℹ️ Information',
      'success' => '✅ Succès',
      'warning' => '⚠️ Avertissement',
      'error' => '❌ Erreur',
      'promotion' => '🎁 Promotion',
      'announcement' => '📢 Annonce',
      'maintenance' => '🔧 Maintenance'
    }[banner_type] || banner_type
  end

  def audience_label
    {
      'all' => 'Tous les clients',
      'active_clients' => 'Clients actifs',
      'inactive_clients' => 'Clients inactifs',
      'with_balance' => 'Clients avec solde',
      'unpaid_commissions' => 'Commissions impayées',
      'new_clients' => 'Nouveaux clients',
      'specific_users' => 'Utilisateurs spécifiques'
    }[target_audience] || target_audience
  end

  def self.visible_for(user)
    current.by_priority.select { |b| b.visible_for?(user) }
  end
end

