class SmsCampaignJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = SmsCampaign.find_by(id: campaign_id)
    return unless campaign

    campaign.send_campaign!
    
    Rails.logger.info "SMS Campaign #{campaign.id} completed: #{campaign.sent_count} sent, #{campaign.failed_count} failed"
  end
end

