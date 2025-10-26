namespace :trade_defender do
  desc "Scan all trades and identify manual trades (magic_number = 0)"
  task scan_all_trades: :environment do
    puts "=" * 80
    puts "TRADE DEFENDER - Scan complet de tous les trades"
    puts "=" * 80
    
    total_trades = Trade.count
    puts "Total trades dans la base: #{total_trades}"
    
    manual_trades = Trade.where(magic_number: 0)
    puts "Trades manuels détectés (magic_number = 0): #{manual_trades.count}"
    
    bot_trades = Trade.where.not(magic_number: 0).where.not(magic_number: nil)
    puts "Trades bots détectés (magic_number > 0): #{bot_trades.count}"
    
    nil_trades = Trade.where(magic_number: nil)
    puts "Trades sans magic_number: #{nil_trades.count}"
    
    puts "\n" + "=" * 80
    puts "Mise à jour des trades..."
    
    Trade.transaction do
      # Mettre à jour les trades manuels (magic_number = 0)
      manual_count = Trade.where(magic_number: 0).update_all(
        trade_originality: 'manual_pending_review',
        is_unauthorized_manual: false
      )
      puts "✓ #{manual_count} trades marqués comme 'En attente' (manual)"
      
      # Mettre à jour les trades bots (magic_number > 0)
      bot_count = Trade.where.not(magic_number: 0).where.not(magic_number: nil).update_all(
        trade_originality: 'bot',
        is_unauthorized_manual: false
      )
      puts "✓ #{bot_count} trades marqués comme 'Bot'"
      
      # Mettre à jour les trades sans magic_number
      nil_count = Trade.where(magic_number: nil).update_all(
        trade_originality: 'unknown',
        is_unauthorized_manual: false
      )
      puts "✓ #{nil_count} trades marqués comme 'Unknown'"
    end
    
    puts "\n" + "=" * 80
    puts "RÉSUMÉ PAR STATUT"
    puts "=" * 80
    
    pending = Trade.where(trade_originality: 'manual_pending_review').count
    admin = Trade.where(trade_originality: 'manual_admin').count
    client = Trade.where(trade_originality: 'manual_client').count
    bot = Trade.where(trade_originality: 'bot').count
    unknown = Trade.where(trade_originality: 'unknown').count
    
    puts "⏳ En attente (manual_pending_review): #{pending}"
    puts "✓ Mes trades (manual_admin): #{admin}"
    puts "⚠️ Clients (manual_client): #{client}"
    puts "🤖 Bots (bot): #{bot}"
    puts "❓ Unknown: #{unknown}"
    
    puts "\n" + "=" * 80
    puts "Scan terminé avec succès !"
    puts "=" * 80
  end
  
  desc "Re-scan specific account trades"
  task :rescan_account, [:mt5_id] => :environment do |t, args|
    if args[:mt5_id].blank?
      puts "Usage: rake trade_defender:rescan_account[MT5_ID]"
      exit
    end
    
    mt5_account = Mt5Account.find_by(mt5_id: args[:mt5_id])
    unless mt5_account
      puts "Compte MT5 #{args[:mt5_id]} introuvable"
      exit
    end
    
    puts "Scan des trades pour le compte: #{mt5_account.account_name} (#{args[:mt5_id]})"
    
    trades = mt5_account.trades
    
    manual_count = 0
    bot_count = 0
    
    trades.each do |trade|
      trade.detect_trade_originality!
      if trade.save
        if trade.trade_originality == 'manual_pending_review'
          manual_count += 1
        elsif trade.trade_originality == 'bot'
          bot_count += 1
        end
      end
    end
    
    puts "✓ #{manual_count} trades manuels en attente"
    puts "✓ #{bot_count} trades bots"
  end
end

