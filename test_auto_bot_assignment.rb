#!/usr/bin/env ruby
# Script de test pour l'assignation automatique des bots

puts "🤖 Test du système d'assignation automatique des bots"
puts "=" * 60

# Vérifier que les modèles sont chargés
begin
  require_relative 'config/environment'
  puts "✅ Environnement Rails chargé"
rescue => e
  puts "❌ Erreur lors du chargement de l'environnement: #{e.message}"
  exit 1
end

# Vérifier les bots disponibles
bots = TradingBot.where.not(magic_number_prefix: nil)
puts "\n📊 Bots disponibles avec magic_number_prefix:"
if bots.any?
  bots.each do |bot|
    puts "  • #{bot.name} (Magic: #{bot.magic_number_prefix})"
  end
else
  puts "  ⚠️  Aucun bot avec magic_number_prefix trouvé"
end

# Vérifier les utilisateurs avec des trades
users_with_trades = User.joins(:trades).distinct
puts "\n👥 Utilisateurs avec des trades: #{users_with_trades.count}"

if users_with_trades.any?
  users_with_trades.limit(3).each do |user|
    puts "\n🔍 Test pour #{user.email}:"
    
    # Afficher les magic numbers des trades
    magic_numbers = user.trades.distinct.pluck(:magic_number).compact
    puts "  Magic numbers détectés: #{magic_numbers.join(', ')}"
    
    # Compter les bots actuels
    current_bots = user.bot_purchases.count
    puts "  Bots assignés actuellement: #{current_bots}"
    
    # Tester la détection automatique
    old_count = user.bot_purchases.count
    user.auto_detect_and_assign_bots
    new_count = user.bot_purchases.count
    
    if new_count > old_count
      puts "  ✅ #{new_count - old_count} nouveau(x) bot(s) assigné(s) automatiquement"
      
      # Afficher les nouveaux bots assignés
      user.bot_purchases.where(purchase_type: 'auto_detected').each do |purchase|
        puts "    🤖 #{purchase.trading_bot.name} (Magic: #{purchase.magic_number})"
      end
    else
      puts "  ℹ️  Aucun nouveau bot détecté"
    end
  end
end

puts "\n🎉 Test terminé !"
puts "\n💡 Pour tester manuellement:"
puts "   rails bots:auto_assign"
puts "   rails bots:stats"
