module Admin
  class BotsController < BaseController
    before_action :require_admin, except: [:show]
    before_action :set_bot, only: [:show, :edit, :update, :destroy, :remove_from_user]

    def index
      @bots = TradingBot.order(created_at: :desc)
    end

    def show
      @purchases = @bot.bot_purchases.includes(:user).order(created_at: :desc)
    end

    def new
      @bot = TradingBot.new
    end

    def create
      @bot = TradingBot.new(bot_params)
      
      if @bot.save
        redirect_to admin_bots_path, notice: "Bot créé avec succès"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @bot.update(bot_params)
        # Gérer l'upload de backtest si fourni
        if params[:backtest_file].present?
          handle_backtest_upload(params[:backtest_file])
        end
        
        redirect_to admin_bot_path(@bot), notice: "Bot mis à jour avec succès"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @bot.destroy
      redirect_to admin_bots_path, notice: "Bot supprimé avec succès"
    end

    def assign_to_user
      user = User.find(params[:user_id])
      bot = TradingBot.find(params[:bot_id])
      
      purchase = BotPurchase.create(
        user: user,
        trading_bot: bot,
        price_paid: params[:price_paid].present? ? params[:price_paid] : bot.price,
        status: 'active'
      )
      
      if purchase.persisted?
        redirect_to admin_client_path(user), notice: "Bot assigné au client avec succès"
      else
        redirect_to admin_client_path(user), alert: "Erreur lors de l'assignation du bot"
      end
    end

    def remove_from_user
      purchase = BotPurchase.find(params[:purchase_id])
      purchase.destroy
      redirect_to admin_client_path(purchase.user), notice: "Bot retiré du client"
    end

    private

    def set_bot
      @bot = TradingBot.find(params[:id])
    end

    def bot_params
      params.require(:trading_bot).permit(
        :name, :description, :price, :status, :image_url,
        :projection_monthly_min, :projection_monthly_max, :projection_yearly,
        :win_rate, :max_drawdown_limit, :strategy_description,
        :risk_level, :is_active, :symbol, :magic_number_prefix, features: []
      )
    end
    
    def handle_backtest_upload(uploaded_file)
      Rails.logger.info "=" * 80
      Rails.logger.info "📤 UPLOAD DE BACKTEST"
      Rails.logger.info "Fichier: #{uploaded_file.original_filename}"
      Rails.logger.info "Taille: #{uploaded_file.size} bytes"
      Rails.logger.info "=" * 80
      
      # Enregistrer le fichier temporairement
      temp_path = Rails.root.join('tmp', "backtest_#{SecureRandom.hex(8)}.xlsx")
      File.binwrite(temp_path, uploaded_file.read)
      
      Rails.logger.info "Fichier temporaire créé: #{temp_path}"
      
      # Parser le fichier Excel
      parsed_data = Mt5ReportParser.parse(temp_path.to_s)
      
      if parsed_data
        Rails.logger.info "✅ Parsing réussi !"
        # Créer le backtest avec les données parsées
        backtest = @bot.backtests.build(
          original_filename: uploaded_file.original_filename,
          start_date: parsed_data[:start_date] || 2.years.ago,
          end_date: parsed_data[:end_date] || Date.today,
          total_trades: parsed_data[:total_trades] || 0,
          winning_trades: parsed_data[:winning_trades] || 0,
          losing_trades: parsed_data[:losing_trades] || 0,
          total_profit: parsed_data[:total_profit] || 0,
          max_drawdown: parsed_data[:max_drawdown] || 0,
          win_rate: parsed_data[:win_rate] || 0,
          average_profit: parsed_data[:average_profit] || 0
        )
        
        # Déplacer le fichier vers storage
        storage_path = Rails.root.join('storage', 'backtests', "#{@bot.id}_#{SecureRandom.hex(8)}.xlsx")
        FileUtils.mkdir_p(storage_path.dirname)
        FileUtils.mv(temp_path, storage_path)
        backtest.file_path = storage_path.to_s
        
        if backtest.save
          Rails.logger.info "✅ Backtest créé avec succès"
          backtest.calculate_projections
          Rails.logger.info "📊 Projections calculées"
          backtest.activate! if @bot.backtests.count == 1
          Rails.logger.info "🟢 Backtest activé"
        else
          Rails.logger.error "❌ Erreur création backtest: #{backtest.errors.full_messages.join(', ')}"
        end
      else
        Rails.logger.error "❌ Parsing échoué - aucune donnée extraite"
        FileUtils.rm_f(temp_path)
      end
      
      Rails.logger.info "=" * 80
    end
  end
end

