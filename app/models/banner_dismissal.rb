class BannerDismissal < ApplicationRecord
  belongs_to :banner
  belongs_to :user

  validates :banner_id, uniqueness: { scope: :user_id }
end

