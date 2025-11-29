module Admin
  class BannersController < BaseController
    before_action :set_banner, only: [:show, :edit, :update, :destroy, :toggle]

    def index
      @banners = Banner.order(priority: :desc, created_at: :desc).page(params[:page]).per(20)
      @active_banners = Banner.current.count
      @stats = {
        total: Banner.count,
        active: @active_banners,
        views: Banner.sum(:views_count),
        clicks: Banner.sum(:clicks_count)
      }
    end

    def show
    end

    def new
      @banner = Banner.new(
        banner_type: 'info',
        target_audience: 'all',
        is_active: true,
        is_dismissible: true,
        priority: 0
      )
    end

    def create
      @banner = Banner.new(banner_params)
      @banner.created_by = current_user

      if @banner.save
        redirect_to admin_banners_path, notice: "Bannière créée avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @banner.update(banner_params)
        redirect_to admin_banners_path, notice: "Bannière mise à jour"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @banner.destroy
      redirect_to admin_banners_path, notice: "Bannière supprimée"
    end

    def toggle
      @banner.update(is_active: !@banner.is_active)
      redirect_to admin_banners_path, notice: "Bannière #{@banner.is_active ? 'activée' : 'désactivée'}"
    end

    private

    def set_banner
      @banner = Banner.find(params[:id])
    end

    def banner_params
      params.require(:banner).permit(
        :title, :content, :banner_type, :icon, :background_color, :text_color,
        :button_text, :button_url, :target_audience, :target_filters,
        :is_dismissible, :is_active, :starts_at, :ends_at, :priority
      )
    end
  end
end

