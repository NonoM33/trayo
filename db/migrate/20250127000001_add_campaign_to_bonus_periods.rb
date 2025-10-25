class AddCampaignToBonusPeriods < ActiveRecord::Migration[8.0]
  def change
    add_reference :bonus_periods, :campaign, null: true, foreign_key: true
  end
end
