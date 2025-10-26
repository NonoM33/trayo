namespace :bots do
  desc "Détecter et assigner automatiquement les bots pour tous les utilisateurs"
  task auto_detect: :environment do
    require_relative '../lib/bot_detection_worker'
    
    puts "🚀 Lancement du worker de détection automatique des bots..."
    puts "=" * 60
    
    assigned_bots = BotDetectionWorker.detect_and_assign_bots_for_all_users
    
    puts "\n📊 Résumé:"
    puts "✅ #{assigned_bots} bots assignés automatiquement"
    puts "🎯 Worker terminé avec succès !"
  end
  
  desc "Détecter et assigner les bots pour un utilisateur spécifique"
  task :detect_for_user, [:email] => :environment do |t, args|
    require_relative '../lib/bot_detection_worker'
    
    email = args[:email]
    unless email
      puts "❌ Veuillez spécifier un email: rake bots:detect_for_user[email@example.com]"
      exit 1
    end
    
    puts "🔍 Détection des bots pour #{email}..."
    puts "=" * 40
    
    assigned_bots = BotDetectionWorker.detect_and_assign_bots_for_user_by_email(email)
    
    puts "\n📊 Résumé:"
    puts "✅ #{assigned_bots} bots assignés à #{email}"
  end
  
  desc "Afficher le statut des bots pour un utilisateur"
  task :status_for_user, [:email] => :environment do |t, args|
    require_relative '../lib/bot_detection_worker'
    
    email = args[:email]
    unless email
      puts "❌ Veuillez spécifier un email: rake bots:status_for_user[email@example.com]"
      exit 1
    end
    
    BotDetectionWorker.show_user_bot_status(email)
  end
  
  desc "Afficher les statistiques globales des bots"
  task stats: :environment do
    puts "📊 Statistiques des bots:"
    puts "=" * 40
    
    total_bots = TradingBot.count
    total_users = User.clients.count
    total_bot_purchases = BotPurchase.count
    auto_detected = BotPurchase.where(purchase_type: 'auto_detected').count
    manual = BotPurchase.where(purchase_type: 'manual').count
    
    puts "🤖 Total bots disponibles: #{total_bots}"
    puts "👥 Total utilisateurs clients: #{total_users}"
    puts "🛒 Total achats de bots: #{total_bot_purchases}"
    puts "🤖 Achats automatiques: #{auto_detected}"
    puts "👤 Achats manuels: #{manual}"
    
    puts "\n📈 Répartition par bot:"
    TradingBot.includes(:bot_purchases).each do |bot|
      purchase_count = bot.bot_purchases.count
      auto_count = bot.bot_purchases.where(purchase_type: 'auto_detected').count
      puts "  - #{bot.name} (#{bot.magic_number_prefix}): #{purchase_count} achats (#{auto_count} auto)"
    end
  end
  
  desc "Nettoyer les doublons de bot_purchases"
  task clean_duplicates: :environment do
    puts "🧹 Nettoyage des doublons de bot_purchases..."
    puts "=" * 40
    
    duplicates = BotPurchase.group(:user_id, :trading_bot_id)
                           .having('COUNT(*) > 1')
                           .count
    
    if duplicates.empty?
      puts "✅ Aucun doublon trouvé"
    else
      puts "⚠️  #{duplicates.count} doublons trouvés"
      
      duplicates.each do |(user_id, trading_bot_id), count|
        user = User.find(user_id)
        bot = TradingBot.find(trading_bot_id)
        
        puts "  - #{user.email} + #{bot.name}: #{count} occurrences"
        
        # Garder le plus récent, supprimer les autres
        purchases = BotPurchase.where(user: user, trading_bot: bot).order(created_at: :desc)
        purchases.offset(1).destroy_all
        
        puts "    ✅ Doublons supprimés"
      end
    end
  end
end
