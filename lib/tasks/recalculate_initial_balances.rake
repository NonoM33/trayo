namespace :mt5 do
  desc "Recalculer toutes les balances initiales des comptes MT5"
  task recalculate_initial_balances: :environment do
    puts "🔄 Recalcul des balances initiales des comptes MT5..."
    puts "=" * 50

    # Trouver tous les comptes MT5
    accounts = Mt5Account.all

    puts "📊 #{accounts.count} comptes MT5 trouvés"
    puts

    accounts.each do |account|
      puts "Compte: #{account.account_name} (#{account.mt5_id})"
      
      # Calculer la somme des dépôts
      total_deposits = account.deposits.sum(:amount) || 0
      puts "  💰 Total des dépôts: #{total_deposits} €"
      
      # Ancienne balance initiale
      old_initial = account.calculated_initial_balance || account.initial_balance || 0
      puts "  📈 Ancienne balance initiale: #{old_initial} €"
      
      # Recalculer
      new_initial = account.calculate_initial_balance_from_history
      puts "  ✅ Nouvelle balance initiale: #{new_initial} €"
      
      # Calculer les nouveaux gains nets
      new_net_gains = account.net_gains
      puts "  📊 Nouveaux gains nets: #{new_net_gains} €"
      
      puts "  " + "-" * 40
      puts
    end

    puts "✅ Recalcul terminé !"
    puts
    puts "💡 La balance initiale est maintenant automatiquement calculée comme :"
    puts "   Balance Initiale = Somme de tous les dépôts"
    puts
    puts "🔄 Les balances initiales seront automatiquement mises à jour quand :"
    puts "   • Un nouveau dépôt est ajouté"
    puts "   • Un dépôt est modifié"
    puts "   • Un dépôt est supprimé"
  end
end
