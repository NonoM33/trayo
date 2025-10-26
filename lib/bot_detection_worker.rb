class BotDetectionWorker
  def self.detect_and_assign_bots_for_all_users
    puts "🤖 Démarrage du worker de détection automatique des bots..."
    puts "=" * 60
    
    total_users = User.clients.count
    processed_users = 0
    assigned_bots = 0
    
    User.clients.includes(:mt5_accounts, :trades, :bot_purchases).find_each do |user|
      next unless user.mt5_accounts.any?
      
      old_bot_count = user.bot_purchases.count
      new_bots_assigned = detect_and_assign_bots_for_user(user)
      
      if new_bots_assigned > 0
        assigned_bots += new_bots_assigned
        puts "✅ #{user.email}: #{new_bots_assigned} bot(s) assigné(s)"
      end
      
      processed_users += 1
      print "\r📊 Progression: #{processed_users}/#{total_users} utilisateurs traités"
    end
    
    puts "\n🎉 Worker terminé !"
    puts "📈 #{assigned_bots} bots assignés automatiquement"
    puts "👥 #{processed_users} utilisateurs traités"
    
    assigned_bots
  end
  
  def self.detect_and_assign_bots_for_user(user)
    return 0 unless user.mt5_accounts.any?
    
    # Récupérer tous les magic numbers uniques des trades de l'utilisateur
    magic_numbers = Trade.joins(mt5_account: :user)
                        .where(users: { id: user.id })
                        .distinct
                        .pluck(:magic_number)
                        .compact
    
    bots_assigned = 0
    
    magic_numbers.each do |magic_number|
      # Chercher un bot qui correspond à ce magic number
      bot = TradingBot.find_by(magic_number_prefix: magic_number)
      
      if bot && !user.bot_purchases.exists?(trading_bot: bot)
        # Créer automatiquement un BotPurchase pour ce bot
        begin
          user.bot_purchases.create!(
            trading_bot: bot,
            price_paid: bot.price,
            status: 'active',
            magic_number: magic_number,
            is_running: true,
            started_at: Time.current,
            purchase_type: 'auto_detected'
          )
          bots_assigned += 1
          
          Rails.logger.info "Bot automatiquement assigné: #{bot.name} (#{magic_number}) pour l'utilisateur #{user.email}"
        rescue => e
          Rails.logger.error "Erreur lors de l'assignation du bot #{bot.name} pour #{user.email}: #{e.message}"
        end
      end
    end
    
    bots_assigned
  end
  
  def self.detect_and_assign_bots_for_user_by_email(email)
    user = User.find_by(email: email)
    return 0 unless user
    
    puts "🔍 Détection des bots pour #{email}..."
    bots_assigned = detect_and_assign_bots_for_user(user)
    
    if bots_assigned > 0
      puts "✅ #{bots_assigned} bot(s) assigné(s) à #{email}"
    else
      puts "ℹ️  Aucun nouveau bot détecté pour #{email}"
    end
    
    bots_assigned
  end
  
  def self.show_user_bot_status(email)
    user = User.find_by(email: email)
    return unless user
    
    puts "📊 Statut des bots pour #{email}:"
    puts "-" * 40
    
    # Afficher les bots assignés
    user.bot_purchases.includes(:trading_bot).each do |purchase|
      puts "✅ #{purchase.trading_bot.name} (#{purchase.magic_number}) - #{purchase.purchase_type}"
    end
    
    # Afficher les magic numbers des trades
    magic_numbers = Trade.joins(mt5_account: :user)
                        .where(users: { id: user.id })
                        .distinct
                        .pluck(:magic_number)
                        .compact
    
    puts "\n🔍 Magic numbers détectés dans les trades:"
    magic_numbers.each do |magic_number|
      bot = TradingBot.find_by(magic_number_prefix: magic_number)
      if bot
        puts "  - #{magic_number} → #{bot.name} #{user.bot_purchases.exists?(trading_bot: bot) ? '(assigné)' : '(non assigné)'}"
      else
        puts "  - #{magic_number} → Aucun bot trouvé"
      end
    end
  end
end
