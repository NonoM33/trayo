module Admin
  class BacktestsController < BaseController
    before_action :require_admin
    before_action :set_bot
    before_action :set_backtest, only: [:show, :destroy, :activate, :recalculate]

    def index
      @backtests = @bot.backtests.latest
    end

    def show
    end

    def new
      @backtest = @bot.backtests.build
    end

    def create
      # Gérer l'upload de fichier
      if params[:backtest][:file].present?
        Rails.logger.info "=" * 80
        Rails.logger.info "📤 UPLOAD DE BACKTEST"
        Rails.logger.info "Fichier: #{params[:backtest][:file].original_filename}"
        Rails.logger.info "=" * 80
        
        uploaded_file = params[:backtest][:file]
        original_filename = uploaded_file.original_filename
        
        # Enregistrer le fichier temporairement
        temp_path = Rails.root.join('tmp', "backtest_#{SecureRandom.hex(8)}.xlsx")
        File.binwrite(temp_path, uploaded_file.read)
        
        Rails.logger.info "Fichier temporaire créé: #{temp_path}"
        
        # Parser le fichier Excel
        parsed_data = Mt5ReportParser.parse(temp_path.to_s)
        
        if parsed_data
          Rails.logger.info "✅ Parsing réussi !"
          
          # Créer le backtest avec les données parsées
          @backtest = @bot.backtests.build(
            original_filename: original_filename,
            start_date: parsed_data[:start_date] || 2.years.ago,
            end_date: parsed_data[:end_date] || Date.today,
            total_trades: parsed_data[:total_trades] || 0,
            winning_trades: parsed_data[:winning_trades] || 0,
            losing_trades: parsed_data[:losing_trades] || 0,
            total_profit: parsed_data[:total_profit] || 0,
            max_drawdown: parsed_data[:max_drawdown] || 0,
            win_rate: parsed_data[:win_rate] || 0,
            average_profit: parsed_data[:average_profit] || 0,
            projection_monthly_min: parsed_data[:projection_monthly_min] || 0,
            projection_monthly_max: parsed_data[:projection_monthly_max] || 0,
            projection_yearly: parsed_data[:projection_yearly] || 0
          )
          
          # Déplacer le fichier vers storage
          storage_path = Rails.root.join('storage', 'backtests', "#{@bot.id}_#{SecureRandom.hex(8)}.xlsx")
          FileUtils.mkdir_p(storage_path.dirname)
          FileUtils.mv(temp_path, storage_path)
          @backtest.file_path = storage_path.to_s
        else
          Rails.logger.error "❌ Parsing échoué - aucune donnée extraite"
          FileUtils.rm_f(temp_path)
          redirect_to new_admin_bot_backtest_path(@bot), alert: "Impossible de parser le fichier Excel. Vérifiez les logs."
          return
        end
      else
        # Pas de fichier uploadé, création manuelle
        Rails.logger.info "📝 Création manuelle du backtest"
        @backtest = @bot.backtests.build(backtest_params)
      end
      
      if @backtest.save
        Rails.logger.info "✅ Backtest créé avec succès"
        @backtest.calculate_projections
        @backtest.save if @backtest.changed?
        Rails.logger.info "📊 Projections calculées: #{@backtest.projection_monthly_min} - #{@backtest.projection_monthly_max}"
        Rails.logger.info "=" * 80
        redirect_to admin_bot_backtests_path(@bot), notice: "Backtest créé avec succès"
      else
        Rails.logger.error "❌ Erreur création backtest: #{@backtest.errors.full_messages.join(', ')}"
        Rails.logger.info "=" * 80
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @backtest.destroy
      redirect_to admin_bot_backtests_path(@bot), notice: "Backtest supprimé avec succès"
    end
    
    def activate
      @backtest.activate!
      redirect_to admin_bot_backtests_path(@bot), notice: "Backtest activé avec succès"
    end
    
    def recalculate
      @backtest.calculate_projections
      @backtest.save if @backtest.changed?
      redirect_to admin_bot_backtests_path(@bot), notice: "Projections recalculées avec succès"
    end

    private

    def set_bot
      @bot = TradingBot.find(params[:bot_id])
    end

    def set_backtest
      @backtest = @bot.backtests.find(params[:id])
    end

    def backtest_params
      params.require(:backtest).permit(
        :start_date, :end_date, :total_trades, :winning_trades, 
        :losing_trades, :total_profit, :max_drawdown, :win_rate, 
        :average_profit
      )
    end
  end
end

