class SmsCampaign < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  has_many :sms_campaign_logs, dependent: :nullify

  STATUSES = %w[draft scheduled sending completed cancelled].freeze
  SMS_TYPES = %w[relance_commission rappel_paiement promotion activation_bot alerte_compte performance maintenance bienvenue personnalise].freeze
  TARGET_AUDIENCES = %w[all_clients active_clients inactive_clients with_balance unpaid_commissions new_clients].freeze
  CAMPAIGN_TYPES = %w[sms email sms_email].freeze
  CHANNELS = %w[sms email].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :sms_type, inclusion: { in: SMS_TYPES }, allow_blank: true
  validates :campaign_type, inclusion: { in: CAMPAIGN_TYPES }

  scope :draft, -> { where(status: 'draft') }
  scope :scheduled, -> { where(status: 'scheduled') }
  scope :completed, -> { where(status: 'completed') }
  scope :sms_campaigns, -> { where(campaign_type: ['sms', 'sms_email']) }
  scope :email_campaigns, -> { where(campaign_type: ['email', 'sms_email']) }

  def sms_enabled?
    campaign_type == 'sms' || campaign_type == 'sms_email'
  end

  def email_enabled?
    campaign_type == 'email' || campaign_type == 'sms_email'
  end

  def campaign_type_label
    {
      'sms' => '📱 SMS uniquement',
      'email' => '📧 Email uniquement',
      'sms_email' => '📱📧 SMS + Email'
    }[campaign_type] || campaign_type
  end

  def draft?
    status == 'draft'
  end

  def scheduled?
    status == 'scheduled'
  end

  def sending?
    status == 'sending'
  end

  def completed?
    status == 'completed'
  end

  def target_users
    case target_audience
    when 'all_clients'
      User.where.not(phone: [nil, ''])
    when 'active_clients'
      User.joins(:bot_purchases).where(bot_purchases: { is_running: true }).where.not(phone: [nil, '']).distinct
    when 'inactive_clients'
      User.left_joins(:bot_purchases).where(bot_purchases: { id: nil }).or(User.left_joins(:bot_purchases).where(bot_purchases: { is_running: false })).where.not(phone: [nil, '']).distinct
    when 'with_balance'
      User.joins(:mt5_accounts).where('mt5_accounts.balance > 0').where.not(phone: [nil, '']).distinct
    when 'unpaid_commissions'
      User.where('commission_balance_due > 0').where.not(phone: [nil, ''])
    when 'new_clients'
      User.where('created_at > ?', 30.days.ago).where.not(phone: [nil, ''])
    else
      User.none
    end
  end

  def send_campaign!
    return false unless draft? || scheduled?

    update!(status: 'sending', sent_at: Time.current)
    users = target_users
    update!(recipients_count: users.count)

    sent = 0
    failed = 0

    users.find_each do |user|
      begin
        message = render_message_for(user)
        SmsService.send_sms(user.phone, message)
        
        sms_campaign_logs.create!(
          user: user,
          sent_by: created_by,
          sms_type: sms_type,
          message: message,
          phone_number: user.phone,
          status: 'sent',
          sent_at: Time.current
        )
        sent += 1
      rescue => e
        sms_campaign_logs.create!(
          user: user,
          sent_by: created_by,
          sms_type: sms_type,
          message: message_template,
          phone_number: user.phone,
          status: 'failed',
          sent_at: Time.current,
          error_message: e.message
        )
        failed += 1
      end
    end

    update!(
      status: 'completed',
      completed_at: Time.current,
      sent_count: sent,
      failed_count: failed
    )

    true
  end

  def render_message_for(user)
    performance = CommissionBillingService.calculate_user_performance(user) rescue {}
    
    message_template
      .gsub('{prenom}', user.first_name.to_s)
      .gsub('{nom}', user.last_name.to_s)
      .gsub('{solde}', (performance[:total_balance] || 0).round(2).to_s)
      .gsub('{commission}', (performance[:pending_commission] || 0).round(2).to_s)
  end

  def type_label
    {
      'relance_commission' => '📢 Relance Commission',
      'rappel_paiement' => '💰 Rappel Paiement',
      'promotion' => '🎉 Promotion',
      'activation_bot' => '🤖 Activation Bot',
      'alerte_compte' => '⚠️ Alerte Compte',
      'performance' => '📊 Performance',
      'maintenance' => '🔧 Maintenance',
      'bienvenue' => '✨ Bienvenue',
      'personnalise' => '📝 Personnalisé'
    }[sms_type] || sms_type
  end

  def audience_label
    {
      'all_clients' => 'Tous les clients',
      'active_clients' => 'Clients actifs (bots running)',
      'inactive_clients' => 'Clients inactifs',
      'with_balance' => 'Clients avec solde > 0',
      'unpaid_commissions' => 'Commissions impayées',
      'new_clients' => 'Nouveaux clients (30 jours)'
    }[target_audience] || target_audience
  end
end

