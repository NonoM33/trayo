namespace :watermark do
  desc "Fix watermarks - set to 0 for accounts without validated payments"
  task fix_for_accounts_without_payments: :environment do
    puts "=== Correction des watermarks pour les comptes sans paiement ==="
    
    User.where(is_admin: false).each do |user|
      validated_payments = user.payments.where(status: 'validated')
      
      if validated_payments.empty?
        user.mt5_accounts.each do |account|
          if account.high_watermark > 0
            account.update!(high_watermark: 0.0)
            puts "✓ #{user.email} - Compte #{account.account_name}: WM réinitialisé à 0 (Balance: #{account.balance}€)"
          end
        end
      else
        puts "  #{user.email}: a des paiements validés, WM OK"
      end
    end
    
    puts "=== Correction terminée ==="
  end
end

