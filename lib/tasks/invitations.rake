namespace :invitations do
  desc "Créer une nouvelle invitation"
  task :create, [:count] => :environment do |t, args|
    count = (args[:count] || 1).to_i
    
    count.times do
      invitation = Invitation.new(
        code: Invitation.generate_unique_code,
        expires_at: 30.days.from_now,
        status: "pending"
      )
      invitation.save!
      
      puts "✓ Invitation créée :"
      puts "  Code: #{invitation.code}"
      puts "  URL: https://join.trayo.fr/#{invitation.code}"
      puts "  Expire: #{invitation.expires_at.strftime('%d/%m/%Y')}"
      puts ""
    end
  end
  
  desc "Lister toutes les invitations"
  task :list => :environment do
    invitations = Invitation.order(created_at: :desc).limit(20)
    
    if invitations.any?
      puts "Dernières invitations :"
      puts "-" * 80
      
      invitations.each do |invitation|
        status = invitation.is_used? ? "❌ Utilisée" : invitation.is_expired? ? "⏰ Expirée" : "✓ Active"
        
        puts "#{status} | Code: #{invitation.code}"
        puts "  Email: #{invitation.email || 'Non renseigné'}"
        puts "  Étape: #{invitation.step}/4"
        puts "  Créée: #{invitation.created_at.strftime('%d/%m/%Y %H:%M')}"
        puts "  URL: https://join.trayo.fr/#{invitation.code}"
        puts "-" * 80
      end
    else
      puts "Aucune invitation trouvée"
    end
  end
  
  desc "Supprimer les invitations expirées"
  task :cleanup => :environment do
    deleted = Invitation.where("expires_at < ? AND status = ?", Time.current, "pending").delete_all
    
    puts "✓ #{deleted} invitation(s) expirée(s) supprimée(s)"
  end
end

