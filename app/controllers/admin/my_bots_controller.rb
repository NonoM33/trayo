module Admin
  class MyBotsController < BaseController
    before_action :set_purchase, only: [:show, :toggle_status]

    def index
 "=== MY BOTS CONTROLLER DEBUG ==="
 "Current user: #{current_user.email}"
 "Current user ID: #{current_user.id}"
 "Is admin: #{current_user.is_admin?}"
      
      if current_user.is_admin?
 "User is admin, redirecting to admin_bots_path"
        redirect_to admin_bots_path
      else
 "User is client, fetching bot purchases..."
        
        # DÉTECTION AUTOMATIQUE : Scanner tous les bots enregistrés et vérifier si le client a des trades
 "Détection automatique de tous les bots pour l'utilisateur connecté"
        
        # Récupérer tous les bots enregistrés avec leur magic number
        registered_bots = TradingBot.where.not(magic_number_prefix: nil)
 "Bots enregistrés trouvés: #{registered_bots.count}"
        
        registered_bots.each do |bot|
 "Vérification du bot: #{bot.name} (magic: #{bot.magic_number_prefix})"
          
          # Vérifier si le client a des trades avec ce magic number
          client_trades = Trade.joins(mt5_account: :user)
                              .where(users: { id: current_user.id })
                              .where(magic_number: bot.magic_number_prefix)
          
          if client_trades.any?
 "Client a #{client_trades.count} trades avec le bot #{bot.name}"
            
            # Vérifier si le bot_purchase existe déjà
            existing_purchase = current_user.bot_purchases.find_by(trading_bot: bot)
            
            if existing_purchase
 "Bot #{bot.name} déjà assigné, synchronisation des performances"
              sync_bot_performance(current_user, bot)
            else
 "Création du bot_purchase pour #{bot.name}"
              
              # Calculer la date d'achat basée sur le premier trade
              first_trade = client_trades.order(:open_time).first
              purchase_date = first_trade&.open_time || Time.current
 "Date d'achat calculée: #{purchase_date}"
              
              # Calculer les performances actuelles
              total_profit = client_trades.sum(:profit)
              trades_count = client_trades.count
              
              # Créer le bot_purchase
              new_purchase = current_user.bot_purchases.create!(
                trading_bot: bot,
                price_paid: bot.price,
                status: 'active',
                magic_number: bot.magic_number_prefix,
                is_running: true,
                total_profit: total_profit,
                trades_count: trades_count,
                current_drawdown: 0,
                max_drawdown_recorded: 0,
                purchase_type: 'auto_detected',
                started_at: purchase_date,
                created_at: purchase_date,
                updated_at: Time.current
              )
              
 "Bot #{bot.name} créé avec ID #{new_purchase.id}, profit: #{total_profit}€, trades: #{trades_count}"
            end
          else
 "Client n'a pas de trades avec le bot #{bot.name}"
          end
        end
        
        # Debug: Vérifier les bot_purchases en base
        all_purchases = BotPurchase.where(user_id: current_user.id)
 "Bot purchases in DB for user #{current_user.id}: #{all_purchases.count}"
        all_purchases.each do |purchase|
 "  - Purchase ID: #{purchase.id}, Bot ID: #{purchase.trading_bot_id}, Status: #{purchase.status}"
        end
        
        # Synchroniser les performances de tous les bots de l'utilisateur
 "Synchronisation des performances de tous les bots..."
        current_user.bot_purchases.includes(:trading_bot).each do |purchase|
          sync_bot_performance(current_user, purchase.trading_bot)
        end
        
        # Debug via le modèle User
        current_user.debug_bot_purchases
        
        @purchases = current_user.bot_purchases.includes(:trading_bot).order(created_at: :desc)
 "Purchases loaded: #{@purchases.count}"
        @purchases.each do |purchase|
 "  - Loaded: #{purchase.trading_bot&.name} (#{purchase.status})"
        end
        
 "Purchases any?: #{@purchases.any?}"
 "Purchases empty?: #{@purchases.empty?}"
 "================================"
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
      # Récupérer tous les trades de l'utilisateur avec le magic number du bot
      trades = Trade.joins(mt5_account: :user)
                   .where(users: { id: user.id })
                   .where(magic_number: bot.magic_number_prefix)
      
      if trades.any?
        # Calculer les statistiques
        total_profit = trades.sum(:profit)
        trades_count = trades.count
        winning_trades = trades.where('profit > 0').count
        losing_trades = trades.where('profit < 0').count
        win_rate = trades_count > 0 ? (winning_trades.to_f / trades_count * 100).round(2) : 0
        
        # Mettre à jour le bot_purchase
        bot_purchase = user.bot_purchases.find_by(trading_bot: bot)
        if bot_purchase
          # Calculer la date d'achat basée sur le premier trade
          first_trade = trades.order(:open_time).first
          purchase_date = first_trade&.open_time || bot_purchase.created_at
          
          bot_purchase.update!(
            total_profit: total_profit,
            trades_count: trades_count,
            current_drawdown: 0, # À calculer si nécessaire
            max_drawdown_recorded: 0, # À calculer si nécessaire
            started_at: purchase_date,
            created_at: purchase_date
          )
        end
      end
    end
  end
end

