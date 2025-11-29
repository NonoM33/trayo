module Admin
  class SmsCampaignsController < BaseController
    before_action :set_campaign, only: [:show, :edit, :update, :destroy, :send_campaign]

    def index
      @campaigns = SmsCampaign.order(created_at: :desc).page(params[:page]).per(20)
      @recent_logs = SmsCampaignLog.recent.includes(:user, :sent_by).limit(50)
      @stats = {
        total_sent: SmsCampaignLog.count,
        sent_today: SmsCampaignLog.where('sent_at > ?', Date.current.beginning_of_day).count,
        failed: SmsCampaignLog.failed.count,
        campaigns: SmsCampaign.count
      }
      
      @banners = Banner.order(priority: :desc, created_at: :desc).page(params[:page]).per(20)
      @banner_stats = {
        total: Banner.count,
        active: Banner.current.count,
        views: Banner.sum(:views_count),
        clicks: Banner.sum(:clicks_count)
      }
    end

    def show
      @logs = @campaign.sms_campaign_logs.recent.includes(:user).page(params[:page]).per(50)
    end

    def new
      @campaign = SmsCampaign.new
    end

    def create
      @campaign = SmsCampaign.new(campaign_params)
      @campaign.created_by = current_user
      @campaign.recipients_count = @campaign.target_users.count

      if @campaign.save
        redirect_to admin_sms_campaigns_path, notice: "Campagne créée avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @campaign.update(campaign_params)
        @campaign.update(recipients_count: @campaign.target_users.count)
        redirect_to admin_sms_campaigns_path, notice: "Campagne mise à jour"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @campaign.destroy
      redirect_to admin_sms_campaigns_path, notice: "Campagne supprimée"
    end

    def send_campaign
      if @campaign.draft? || @campaign.scheduled?
        SmsCampaignJob.perform_later(@campaign.id)
        redirect_to admin_sms_campaign_path(@campaign), notice: "Envoi de la campagne lancé..."
      else
        redirect_to admin_sms_campaign_path(@campaign), alert: "Cette campagne ne peut pas être envoyée"
      end
    end

    def preview
      @campaign = SmsCampaign.new(campaign_params)
      @preview_users = @campaign.target_users.limit(5)
      
      render json: {
        recipients_count: @campaign.target_users.count,
        preview_messages: @preview_users.map { |u| { name: u.full_name, message: @campaign.render_message_for(u) } }
      }
    end

    private

    def set_campaign
      @campaign = SmsCampaign.find(params[:id])
    end

    def campaign_params
      params.require(:sms_campaign).permit(:name, :sms_type, :message_template, :target_audience, :scheduled_at, :campaign_type, :email_subject, :email_body)
    end
  end
end

