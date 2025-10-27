class Invitation < ApplicationRecord
  before_create :generate_code
  before_validation :set_default_expiration
  
  validates :code, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :budget, numericality: { greater_than: 0 }, allow_blank: true
  
  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :used, -> { where.not(used_at: nil) }
  scope :active, -> { where("expires_at > ?", Time.current) }
  
  def self.generate_unique_code
    loop do
      code = SecureRandom.hex(12).upcase
      break code unless exists?(code: code)
    end
  end
  
  def is_used?
    used_at.present? || status == "completed"
  end
  
  def is_expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def is_valid?
    !is_used? && !is_expired?
  end
  
  def complete!
    update(status: "completed", used_at: Time.current)
  end
  
  def broker_data_parsed
    return {} unless broker_data.present?
    JSON.parse(broker_data)
  rescue JSON::ParserError
    {}
  end
  
  def broker_credentials_parsed
    return {} unless broker_credentials.present?
    JSON.parse(broker_credentials)
  rescue JSON::ParserError
    {}
  end
  
  def selected_bots_parsed
    return [] unless selected_bots.present?
    JSON.parse(selected_bots)
  rescue JSON::ParserError
    []
  end
  
  private
  
  def generate_code
    self.code ||= Invitation.generate_unique_code
  end
  
  def set_default_expiration
    self.expires_at ||= 30.days.from_now if expires_at.nil?
  end
end

