namespace :bots do
  desc "Détecter et assigner automatiquement les bots pour tous les utilisateurs"
  task auto_assign: :environment do
    puts "🤖 Détection automatique des bots en cours..."
    
    total_users = User.clients.count
    processed_users = 0
    assigned_bots = 0
    
    User.clients.includes(:mt5_accounts, :trades, :bot_purchases).find_each do |user|
      next unless user.mt5_accounts.any?
      
      old_bot_count = user.bot_purchases.count
      user.auto_detect_and_assign_bots
      new_bot_count = user.bot_purchases.count
      
      if new_bot_count > old_bot_count
        assigned_bots += (new_bot_count - old_bot_count)
        puts "✅ #{user.email}: #{new_bot_count - old_bot_count} bot(s) assigné(s)"
      end
      
      processed_users += 1
      print "\r📊 Progression: #{processed_users}/#{total_users} utilisateurs traités"
    end
    
    puts "\n🎉 Détection terminée !"
    puts "📈 #{assigned_bots} bots assignés automatiquement"
    puts "👥 #{processed_users} utilisateurs traités"
  end
  
  desc "Afficher les statistiques des bots assignés"
  task stats: :environment do
    puts "📊 Statistiques des bots assignés"
    puts "=" * 50
    
    total_bots = BotPurchase.count
    auto_assigned = BotPurchase.where(purchase_type: 'auto_detected').count
    manual_assigned = BotPurchase.where(purchase_type: 'manual').count
    
    puts "🤖 Total des bots assignés: #{total_bots}"
    puts "🔄 Assignations automatiques: #{auto_assigned}"
    puts "✋ Assignations manuelles: #{manual_assigned}"
    
    puts "\n📈 Répartition par type:"
    BotPurchase.joins(:trading_bot)
               .group('trading_bots.name')
               .count
               .each do |bot_name, count|
      puts "  • #{bot_name}: #{count} assignation(s)"
    end
    
    puts "\n🎯 Utilisateurs avec bots:"
    User.joins(:bot_purchases)
        .distinct
        .count
        .tap { |count| puts "  • #{count} utilisateur(s) ont au moins un bot assigné" }
  end
end
