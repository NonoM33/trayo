namespace :watermark do
  desc "Reset all watermarks to 0 - will be updated only via payments"
  task reset_all: :environment do
    puts "=== Reset des watermarks à 0 ==="
    
    Mt5Account.update_all(high_watermark: 0.0)
    
    puts "✓ Tous les watermarks ont été réinitialisés à 0"
    puts "=== Migration terminée ==="
  end
end

