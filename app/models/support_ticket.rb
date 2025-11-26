class SupportTicket < ApplicationRecord
  STATUSES = %w[open in_progress waiting_for_user closed].freeze

  belongs_to :user, optional: true

  validates :phone_number, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :ticket_number, presence: true, uniqueness: true
  validates :description, presence: true

  before_validation :generate_ticket_number, on: :create
  before_validation :normalize_phone_number, on: :create

  scope :open, -> { where(status: ["open", "in_progress", "waiting_for_user"]) }
  scope :closed, -> { where(status: "closed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def open?
    status != "closed"
  end

  def closed?
    status == "closed"
  end

  def status_label
    case status
    when "open" then "Ouvert"
    when "in_progress" then "En cours"
    when "waiting_for_user" then "En attente client"
    when "closed" then "Fermé"
    else status.humanize
    end
  end

  def status_badge_class
    case status
    when "open" then "badge-warning"
    when "in_progress" then "badge-info"
    when "waiting_for_user" then "badge-secondary"
    when "closed" then "badge-success"
    else "badge-secondary"
    end
  end

  private

  def generate_ticket_number
    return if ticket_number.present?

    loop do
      self.ticket_number = "TKT-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless self.class.exists?(ticket_number: ticket_number)
    end
  end

  def normalize_phone_number
    return if phone_number.blank?

    cleaned = phone_number.to_s.gsub(/\s+/, "")
    
    if cleaned.start_with?("+33")
      self.phone_number = cleaned
    elsif cleaned.start_with?("33") && cleaned.length >= 11
      self.phone_number = "+#{cleaned}"
    elsif cleaned.start_with?("0")
      self.phone_number = "+33#{cleaned[1..-1]}"
    else
      self.phone_number = "+33#{cleaned}"
    end
  end
end
