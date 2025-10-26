class Mt5Token < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :description, presence: true

  before_create :generate_token

  scope :unused, -> { where(used_at: nil) }
  scope :used, -> { where.not(used_at: nil) }

  def used?
    used_at.present?
  end

  def mark_as_used!
    update!(used_at: Time.current)
  end

  def status
    used? ? 'Utilisé' : 'Disponible'
  end

  def status_color
    used? ? 'error' : 'success'
  end

  private

  def generate_token
    self.token = User.generate_mt5_registration_token
  end
end
