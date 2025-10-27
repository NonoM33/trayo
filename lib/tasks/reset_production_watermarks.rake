namespace :watermark do
  desc "Reset watermarks to 0 for accounts without validated payments"
  task reset_production_accounts: :environment do
    puts "=== Réinitialisation des watermarks ==="
    puts ""
    
    accounts_reset = 0
    
    Mt5Account.find_each do |account|
      user = account.user
      next unless user
      
      # Vérifier si l'utilisateur a des paiements validés
      has_validated_payments = user.payments.where(status: 'validated').any?
      
      if !has_validated_payments && account.high_watermark > 0
        puts "✓ Réinitialisation: #{account.account_name} (User: #{user.email})"
        puts "  WM: #{account.high_watermark}€ → 0€"
        account.update_column(:high_watermark, 0.0)
        accounts_reset += 1
      elsif has_validated_payments
        puts "  Conserve: #{account.account_name} (a des paiements validés, WM: #{account.high_watermark}€)"
      elsif account.high_watermark == 0
        puts "  OK: #{account.account_name} (WM déjà à 0€)"
      end
    end
    
    puts ""
    puts "=== Résultat ==="
    puts "#{accounts_reset} compte(s) réinitialisé(s)"
  end
end
