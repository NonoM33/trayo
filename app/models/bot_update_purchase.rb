class BotUpdatePurchase < ApplicationRecord
  PURCHASE_TYPES = %w[single yearly_pass].freeze
  STATUSES = %w[pending completed cancelled refunded].freeze

  belongs_to :user
  belongs_to :bot_purchase
  belongs_to :bot_update

  validates :purchase_type, inclusion: { in: PURCHASE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :price_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bot_update_id, uniqueness: { scope: :user_id, message: "already purchased" }

  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :yearly_passes, -> { where(purchase_type: 'yearly_pass') }
  scope :recent, -> { order(created_at: :desc) }

  after_update :apply_upgrade, if: :status_changed_to_completed?

  def complete!
    update!(status: 'completed', paid_at: Time.current)
  end

  def yearly_pass?
    purchase_type == 'yearly_pass'
  end

  private

  def status_changed_to_completed?
    saved_change_to_status? && status == 'completed'
  end

  def apply_upgrade
    if yearly_pass?
      bot_purchase.update!(
        has_update_pass: true,
        update_pass_expires_at: 1.year.from_now,
        version_purchased: bot_update.version
      )
    else
      bot_update.upgrade_user!(user)
    end
  end
end

