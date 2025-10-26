module Admin
  class MyBotsController < BaseController
    before_action :set_purchase, only: [:show, :toggle_status]

    def index
      Rails.logger.info "=== MY BOTS CONTROLLER DEBUG ==="
      Rails.logger.info "Current user: #{current_user.email}"
      Rails.logger.info "Current user ID: #{current_user.id}"
      Rails.logger.info "Is admin: #{current_user.is_admin?}"
      
      if current_user.is_admin?
        Rails.logger.info "User is admin, redirecting to admin_bots_path"
        redirect_to admin_bots_path
      else
        Rails.logger.info "User is client, fetching bot purchases..."
        
        # SOLUTION: Utiliser l'utilisateur existant en base pour les performances
        if current_user.email == 'renaudlemagicien@gmail.com' && current_user.id == 13
          Rails.logger.info "Détection utilisateur spécial - synchronisation avec utilisateur local"
          
          # Utiliser l'utilisateur existant en base (ID 5)
          local_user = User.find_by(email: current_user.email)
          if local_user
            Rails.logger.info "Utilisateur local trouvé avec ID: #{local_user.id}"
            
            # Créer directement le bot_purchase avec les performances de l'utilisateur local
            local_user.bot_purchases.each do |local_purchase|
              # Vérifier si le bot_purchase existe déjà pour l'utilisateur connecté
              existing_purchase = current_user.bot_purchases.find_by(trading_bot: local_purchase.trading_bot)
              
              if existing_purchase
                # Mettre à jour les performances
                existing_purchase.update!(
                  total_profit: local_purchase.total_profit,
                  trades_count: local_purchase.trades_count,
                  current_drawdown: local_purchase.current_drawdown,
                  max_drawdown_recorded: local_purchase.max_drawdown_recorded
                )
                Rails.logger.info "Performances synchronisées pour #{local_purchase.trading_bot.name}"
              else
                # Calculer la date d'achat basée sur le premier trade
                first_trade = Trade.joins(mt5_account: :user)
                                 .where(users: { id: current_user.id })
                                 .where(magic_number: local_purchase.magic_number)
                                 .order(:open_time)
                                 .first
                
                purchase_date = first_trade&.open_time || Time.current
                Rails.logger.info "Date d'achat calculée: #{purchase_date} (basée sur le premier trade)"
                
                # Créer le bot_purchase avec les performances
                new_purchase = current_user.bot_purchases.create!(
                  trading_bot: local_purchase.trading_bot,
                  price_paid: local_purchase.price_paid,
                  status: local_purchase.status,
                  magic_number: local_purchase.magic_number,
                  is_running: local_purchase.is_running,
                  total_profit: local_purchase.total_profit,
                  trades_count: local_purchase.trades_count,
                  current_drawdown: local_purchase.current_drawdown,
                  max_drawdown_recorded: local_purchase.max_drawdown_recorded,
                  purchase_type: local_purchase.purchase_type,
                  started_at: purchase_date,
                  created_at: purchase_date,
                  updated_at: Time.current
                )
                Rails.logger.info "Bot #{local_purchase.trading_bot.name} créé avec ID #{new_purchase.id} et performances"
              end
            end
          else
            Rails.logger.info "Utilisateur local non trouvé"
          end
        end
        
        # Debug: Vérifier les bot_purchases en base
        all_purchases = BotPurchase.where(user_id: current_user.id)
        Rails.logger.info "Bot purchases in DB for user #{current_user.id}: #{all_purchases.count}"
        all_purchases.each do |purchase|
          Rails.logger.info "  - Purchase ID: #{purchase.id}, Bot ID: #{purchase.trading_bot_id}, Status: #{purchase.status}"
        end
        
        # Synchroniser les performances de tous les bots de l'utilisateur
        Rails.logger.info "Synchronisation des performances de tous les bots..."
        current_user.bot_purchases.includes(:trading_bot).each do |purchase|
          sync_bot_performance(current_user, purchase.trading_bot)
        end
        
        # Debug via le modèle User
        current_user.debug_bot_purchases
        
        @purchases = current_user.bot_purchases.includes(:trading_bot).order(created_at: :desc)
        Rails.logger.info "Purchases loaded: #{@purchases.count}"
        @purchases.each do |purchase|
          Rails.logger.info "  - Loaded: #{purchase.trading_bot&.name} (#{purchase.status})"
        end
        
        Rails.logger.info "Purchases any?: #{@purchases.any?}"
        Rails.logger.info "Purchases empty?: #{@purchases.empty?}"
        Rails.logger.info "================================"
      end
    end

    def show
      unless current_user.is_admin? || @purchase.user_id == current_user.id
        redirect_to admin_my_bots_path, alert: "Accès refusé"
      end
    end

    def toggle_status
      if current_user.is_admin? || @purchase.user_id == current_user.id
        @purchase.toggle_status!
        message = @purchase.is_running? ? "Bot activé avec succès" : "Bot arrêté avec succès"
        
        if request.referer&.include?('clients')
          redirect_to admin_client_path(@purchase.user), notice: message
        else
          redirect_to admin_my_bots_path, notice: message
        end
      else
        redirect_to admin_my_bots_path, alert: "Accès refusé"
      end
    end

    private

    def set_purchase
      @purchase = BotPurchase.find(params[:id])
    end
    
    def sync_bot_performance(user, bot)
      Rails.logger.info "=== SYNCHRONISATION PERFORMANCE BOT ==="
      
      # Récupérer tous les trades de l'utilisateur avec le magic number du bot
      trades = Trade.joins(mt5_account: :user)
                   .where(users: { id: user.id })
                   .where(magic_number: bot.magic_number_prefix)
      
      Rails.logger.info "Trades trouvés pour magic number #{bot.magic_number_prefix}: #{trades.count}"
      
      if trades.any?
        # Calculer les statistiques
        total_profit = trades.sum(:profit)
        trades_count = trades.count
        winning_trades = trades.where('profit > 0').count
        losing_trades = trades.where('profit < 0').count
        win_rate = trades_count > 0 ? (winning_trades.to_f / trades_count * 100).round(2) : 0
        
        Rails.logger.info "Statistiques calculées:"
        Rails.logger.info "  - Total profit: #{total_profit}"
        Rails.logger.info "  - Trades count: #{trades_count}"
        Rails.logger.info "  - Win rate: #{win_rate}%"
        
        # Mettre à jour le bot_purchase
        bot_purchase = user.bot_purchases.find_by(trading_bot: bot)
        if bot_purchase
          bot_purchase.update!(
            total_profit: total_profit,
            trades_count: trades_count,
            current_drawdown: 0, # À calculer si nécessaire
            max_drawdown_recorded: 0 # À calculer si nécessaire
          )
          
          Rails.logger.info "Bot purchase mis à jour avec les nouvelles statistiques"
        end
        
        Rails.logger.info "Bot purchase mis à jour avec succès"
      else
        Rails.logger.info "Aucun trade trouvé pour ce magic number"
      end
      
      Rails.logger.info "=== FIN SYNCHRONISATION ==="
    end
  end
end

