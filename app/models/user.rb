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
    Rails.logger.info "=== USER DEBUG BOT PURCHASES ==="
    Rails.logger.info "User: #{email} (ID: #{id})"
    
    # Vérifier directement en base
    direct_purchases = BotPurchase.where(user_id: id)
    Rails.logger.info "Direct purchases in DB: #{direct_purchases.count}"
    direct_purchases.each do |purchase|
      Rails.logger.info "  - Purchase ID: #{purchase.id}, Bot ID: #{purchase.trading_bot_id}, Status: #{purchase.status}"
    end
    
    # Vérifier via la relation
    relation_purchases = bot_purchases
    Rails.logger.info "Relation purchases: #{relation_purchases.count}"
    relation_purchases.each do |purchase|
      Rails.logger.info "  - Relation Purchase ID: #{purchase.id}, Bot: #{purchase.trading_bot&.name}"
    end
    
    Rails.logger.info "================================"
  end

  def total_profits
    mt5_accounts.reload.sum { |account| account.net_gains }
  end

  def total_commissionable_gains
    mt5_accounts.reload.sum { |account| account.commissionable_gains }
  end

  def total_commission_due
    return 0 if commission_rate.zero?
    (total_commissionable_gains * commission_rate / 100).round(2)
  end

  def total_validated_payments
    payments.validated.sum(:amount)
  end

  def total_credits
    credits.sum(:amount)
  end

  def balance_due
    (total_commission_due - total_credits).round(2)
  end

  # Détecter automatiquement les bots basés sur les magic numbers des trades
  def auto_detect_and_assign_bots
    return unless mt5_accounts.any?
    
    # Récupérer tous les magic numbers uniques des trades de l'utilisateur
    magic_numbers = trades.distinct.pluck(:magic_number).compact
    
    magic_numbers.each do |magic_number|
      # Chercher un bot qui correspond à ce magic number
      bot = TradingBot.find_by(magic_number_prefix: magic_number)
      
      if bot && !bot_purchases.exists?(trading_bot: bot)
        # Créer automatiquement un BotPurchase pour ce bot
        create_auto_bot_purchase(bot, magic_number)
      end
    end
  end

  # Créer un BotPurchase automatique
  def create_auto_bot_purchase(trading_bot, magic_number)
    bot_purchase = bot_purchases.create!(
      trading_bot: trading_bot,
      price_paid: trading_bot.price, # Prix standard du bot
      status: 'active',
      magic_number: magic_number,
      is_running: true,
      started_at: Time.current,
      purchase_type: 'auto_detected' # Nouveau champ pour distinguer les achats automatiques
    )
    
    Rails.logger.info "Bot automatiquement assigné: #{trading_bot.name} (#{magic_number}) pour l'utilisateur #{email}"
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
      commission_rate: 0, # Par défaut, pas de commission
      is_admin: false,
      init_mt5: false # Pas encore initialisé
    )
    
    # Enregistrer le token comme utilisé
    Mt5Token.create!(
      token: mt5_token,
      description: "Token utilisé automatiquement",
      client_name: "#{first_name} #{last_name}",
      used_at: Time.current
    )
    
    Rails.logger.info "Utilisateur auto-créé: #{user.email} (#{user.first_name} #{user.last_name})"
    user
  end

  private

  def generate_mt5_api_token
    self.mt5_api_token = SecureRandom.hex(32)
  end
end

