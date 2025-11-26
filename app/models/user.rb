class User < ApplicationRecord
  has_secure_password

  has_many :mt5_accounts, dependent: :destroy
  has_many :trades, through: :mt5_accounts
  has_many :payments, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :bonus_deposits, dependent: :destroy
  has_many :bot_purchases, dependent: :destroy
  has_many :trading_bots, through: :bot_purchases
  has_many :vps, class_name: 'Vps', dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :invoice_payments, through: :invoices

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :mt5_api_token, uniqueness: true, allow_nil: true
  validates :commission_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  before_create :generate_mt5_api_token

  scope :clients, -> { where(is_admin: false) }
  scope :admins, -> { where(is_admin: true) }
  scope :mt5_initialized, -> { where(init_mt5: true) }
  scope :mt5_not_initialized, -> { where(init_mt5: false) }

  def debug_bot_purchases
 "=== USER DEBUG BOT PURCHASES ==="
 "User: #{email} (ID: #{id})"
    
    # Vérifier directement en base
    direct_purchases = BotPurchase.where(user_id: id)
 "Direct purchases in DB: #{direct_purchases.count}"
    direct_purchases.each do |purchase|
 "  - Purchase ID: #{purchase.id}, Bot ID: #{purchase.trading_bot_id}, Status: #{purchase.status}"
    end
    
    # Vérifier via la relation
    relation_purchases = bot_purchases
 "Relation purchases: #{relation_purchases.count}"
    relation_purchases.each do |purchase|
 "  - Relation Purchase ID: #{purchase.id}, Bot: #{purchase.trading_bot&.name}"
    end
    
 "================================"
  end

  def total_profits
    mt5_accounts.reload.sum { |account| account.net_gains }
  end

  def total_commissionable_gains
    return 0 unless mt5_accounts.any?
    mt5_accounts.reload.sum { |account| account.commissionable_gains || 0 }
  end

  def watermark_difference
    return 0 unless mt5_accounts.any?
    total_balance = mt5_accounts.reload.sum { |account| account.balance || 0 }
    total_watermark = mt5_accounts.reload.sum { |account| account.high_watermark || 0 }
    (total_balance - total_watermark).round(2)
  end

  def total_commission_due
    return 0 if commission_rate.nil? || commission_rate.zero?
    gains = total_commissionable_gains
    return 0 if gains.nil? || gains.zero?
    (gains * commission_rate / 100).round(2)
  end

  def total_validated_payments
    payments.validated.sum(:amount) || 0
  end

  def total_credits
    credits.sum(:amount) || 0
  end

  def outstanding_invoices_total
    invoices.sum(:balance_due).round(2)
  end

  def total_balance_snapshot
    mt5_accounts.sum(:balance).to_f.round(2)
  end

  def average_daily_gain(days: 30)
    return 0 unless trades.exists?
    from_date = days.days.ago.beginning_of_day
    daily_profits = trades.where('close_time >= ?', from_date)
                          .where.not(close_time: nil)
                          .group("DATE(close_time)")
                          .sum(:profit)
    return 0 if daily_profits.empty?
    (daily_profits.values.sum.to_f / daily_profits.size).round(2)
  end

  def balance_due
    # RÈGLE FONDAMENTALE : 
    # Les paiements validés mettent à jour le watermark lors de la validation
    # Le watermark actuel représente le niveau jusqu'auquel les commissions ont été payées
    # Les gains commissionnables actuels sont calculés depuis ce watermark
    # Donc le solde à payer = Commission due actuelle - Crédits uniquement
    # Les paiements ne sont PAS soustraits car ils sont déjà reflétés dans le watermark
    
    commission_due = total_commission_due || 0
    credits = total_credits || 0
    (commission_due - credits).round(2)
  end

  # Détecter automatiquement les bots basés sur les bots enregistrés
  def auto_detect_and_assign_bots
    return unless mt5_accounts.any?
    
    # Récupérer tous les bots enregistrés avec leur magic number
    registered_bots = TradingBot.where.not(magic_number_prefix: nil)
    
    registered_bots.each do |bot|
      # Vérifier si l'utilisateur a des trades avec ce magic number
      user_trades = trades.where(magic_number: bot.magic_number_prefix)
      
      if user_trades.any? && !bot_purchases.exists?(trading_bot: bot)
        # Créer automatiquement un BotPurchase pour ce bot
        create_auto_bot_purchase(bot, bot.magic_number_prefix)
      end
    end
  end

  # Créer un BotPurchase automatique
  def create_auto_bot_purchase(trading_bot, magic_number)
    # Calculer la date d'achat basée sur le premier trade
    first_trade = trades.where(magic_number: magic_number).order(:open_time).first
    purchase_date = first_trade&.open_time || Time.current
    
    bot_purchase = bot_purchases.create!(
      trading_bot: trading_bot,
      price_paid: trading_bot.price, # Prix standard du bot
      status: 'active',
      magic_number: magic_number,
      is_running: true,
      started_at: purchase_date,
      created_at: purchase_date,
      purchase_type: 'auto_detected' # Nouveau champ pour distinguer les achats automatiques
    )
    
 "Bot automatiquement assigné: #{trading_bot.name} (#{magic_number}) pour l'utilisateur #{email} - Date d'achat: #{purchase_date}"
    bot_purchase
  end

  def pending_payments_total
    payments.pending.sum(:amount)
  end

  # Générer un token MT5 spécial pour auto-inscription
  def self.generate_mt5_registration_token
    "MT5_" + SecureRandom.hex(16).upcase
  end

  # Créer un utilisateur automatiquement à partir des données MT5
  def self.create_from_mt5_data(mt5_data)
    # Extraire les informations du nom du compte MT5
    account_name = mt5_data[:account_name] || "Compte MT5"
    
    # Parser le nom pour extraire prénom/nom si possible
    name_parts = account_name.split
    first_name = name_parts.first || "Utilisateur"
    last_name = name_parts[1..-1].join(" ") || "MT5"
    
    # Utiliser l'email du client s'il est fourni, sinon générer un email unique
    mt5_token = mt5_data[:mt5_api_token]
    email = mt5_data[:client_email].present? ? mt5_data[:client_email] : "mt5_#{mt5_token.downcase}@trayo.auto"
    
    # Vérifier si l'utilisateur existe déjà
    existing_user = User.find_by(email: email)
    if existing_user
      Rails.logger.warn "Utilisateur avec email #{email} existe déjà. Mise à jour du token MT5."
      existing_user.update(mt5_api_token: mt5_token) if existing_user.mt5_api_token.blank?
      return existing_user
    end
    
    # Générer un mot de passe aléatoire
    random_password = SecureRandom.hex(16)
    
    # Créer l'utilisateur
    user = create!(
      email: email,
      first_name: first_name,
      last_name: last_name,
      password: random_password,
      password_confirmation: random_password,
      mt5_api_token: mt5_token,
      commission_rate: 0,
      is_admin: false,
      init_mt5: false
    )
    
    # Enregistrer le token comme utilisé
    Mt5Token.create!(
      token: mt5_token,
      description: "Token utilisé automatiquement",
      client_name: "#{first_name} #{last_name}",
      used_at: Time.current
    ) rescue nil
    
    Rails.logger.info "Utilisateur auto-créé: #{user.email} (#{user.first_name} #{user.last_name})"
    user
  end

  private

  def generate_mt5_api_token
    self.mt5_api_token = SecureRandom.hex(32)
  end
end

