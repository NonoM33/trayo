class BotUpdate < ApplicationRecord
  belongs_to :trading_bot
  has_many :bot_update_purchases, dependent: :destroy
  has_many :users, through: :bot_update_purchases

  validates :version, presence: true, uniqueness: { scope: :trading_bot_id }
  validates :title, presence: true

  scope :released, -> { where("released_at <= ?", Time.current) }
  scope :major, -> { where(is_major: true) }
  scope :recent, -> { order(released_at: :desc) }
  scope :pending_notification, -> { where(notify_users: true) }

  after_create :update_bot_version

  def version_display
    is_major? ? "v#{version} (Majeure)" : "v#{version}"
  end

  def free?
    is_free?
  end

  def price_for_user(user)
    return 0 if is_free?
    
    bot_purchase = user.bot_purchases.find_by(trading_bot_id: trading_bot_id)
    return trading_bot.update_price unless bot_purchase
    
    if bot_purchase.has_update_pass? && bot_purchase.update_pass_expires_at&.future?
      0
    else
      trading_bot.update_price
    end
  end

  def purchasable_by?(user)
    return false unless user
    
    bot_purchase = user.bot_purchases.find_by(trading_bot_id: trading_bot_id)
    return false unless bot_purchase
    
    return false if bot_purchase.version_purchased >= version
    
    return true if is_free?
    return true if bot_purchase.has_update_pass? && bot_purchase.update_pass_expires_at&.future?
    
    !bot_update_purchases.exists?(user: user, status: 'completed')
  end

  def already_upgraded?(user)
    return false unless user
    
    bot_purchase = user.bot_purchases.find_by(trading_bot_id: trading_bot_id)
    return false unless bot_purchase
    
    bot_purchase.version_purchased >= version
  end

  def highlights_list
    return [] if highlights.blank?
    highlights.split("\n").map(&:strip).reject(&:blank?)
  end

  def changelog_list
    return [] if changelog.blank?
    changelog.split("\n").map(&:strip).reject(&:blank?)
  end

  def upgrade_user!(user)
    bot_purchase = user.bot_purchases.find_by(trading_bot_id: trading_bot_id)
    return false unless bot_purchase
    
    bot_purchase.update!(version_purchased: version)
    increment!(:upgrade_count)
    true
  end

  private

  def update_bot_version
    trading_bot.update!(current_version: version) if version > (trading_bot.current_version || "0.0.0")
  end
end

