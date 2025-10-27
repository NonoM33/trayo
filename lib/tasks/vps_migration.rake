namespace :vps do
  desc "Create VPS for existing clients with trades but no VPS"
  task create_for_existing_clients: :environment do
    puts "=== Création des VPS pour les clients existants ==="
    
    clients_with_trades = User.where(is_admin: false)
                               .joins(:mt5_accounts)
                               .joins('INNER JOIN trades ON trades.mt5_account_id = mt5_accounts.id')
                               .distinct
                               .includes(:vps, :mt5_accounts, :trades)
    
    clients_with_trades.each do |client|
      next if client.vps.any?
      
      first_trade = Trade.joins(mt5_account: :user)
                        .where(users: { id: client.id })
                        .where(mt5_accounts: { is_admin_account: false })
                        .order(:open_time)
                        .first
      
      next unless first_trade
      
      first_trade_date = first_trade.open_time
      
      vps = client.vps.create!(
        name: "VPS #{client.mt5_accounts.first.account_name}",
        server_location: "Standard",
        status: 'active',
        monthly_price: 399.99,
        renewal_date: first_trade_date.to_date + 1.year,
        ordered_at: first_trade_date,
        activated_at: Time.current,
        notes: "Créé automatiquement pour les clients existants"
      )
      
      puts "✓ VPS créé pour #{client.email} (ID: #{client.id}) - Date renouvellement: #{vps.renewal_date}"
    end
    
    puts "=== Migration terminée ==="
  end
end

