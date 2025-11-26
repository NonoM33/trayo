class TicketComment < ApplicationRecord
  belongs_to :support_ticket
  belongs_to :user, optional: true

  validates :content, presence: true

  scope :visible, -> { where(is_internal: false) }
  scope :internal, -> { where(is_internal: true) }
  scope :recent, -> { order(created_at: :desc) }

  def author_display_name
    if user
      user.first_name.presence || user.email
    elsif author_name.present?
      author_name
    else
      "Anonyme"
    end
  end

  def author_email_display
    user&.email || author_email || "N/A"
  end

  def is_admin_comment?
    user&.is_admin? || false
  end
end
