module Admin
  class CampaignsController < BaseController
    def index
      @tab = params[:tab] || 'banners'
      
      @banners = Banner.order(priority: :desc, created_at: :desc)
      @sms_campaigns = SmsCampaign.order(created_at: :desc)
      
      @banner_stats = {
        total: Banner.count,
        active: Banner.current.count,
        scheduled: Banner.where('starts_at > ?', Time.current).count,
        in_progress: Banner.current.where(is_active: true).count
      }
      
      @sms_stats = {
        total: SmsCampaign.count,
        in_progress: SmsCampaign.where(status: 'sending').count,
        scheduled: SmsCampaign.where(status: 'scheduled').count,
        completed: SmsCampaign.where(status: 'completed').count
      }
    end
  end
end
