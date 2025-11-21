namespace :backups do
  desc "Create a daily backup of the database"
  task daily: :environment do
    puts "Creating daily backup..."
    
    begin
      backup = BackupService.create_backup(notes: "Backup journalier automatique")
      puts "✓ Backup créé avec succès: #{backup.filename} (#{backup.file_size_human})"
    rescue => e
      puts "✗ Erreur lors de la création du backup: #{e.message}"
      Rails.logger.error "Daily backup failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  desc "Cleanup old backups (older than retention period)"
  task cleanup: :environment do
    puts "Cleaning up old backups..."
    
    begin
      BackupService.cleanup_old_backups
      puts "✓ Nettoyage terminé"
    rescue => e
      puts "✗ Erreur lors du nettoyage: #{e.message}"
      Rails.logger.error "Backup cleanup failed: #{e.message}"
      raise e
    end
  end

  desc "Create backup and cleanup old ones"
  task create_and_cleanup: :environment do
    Rake::Task['backups:daily'].invoke
    Rake::Task['backups:cleanup'].invoke
  end
end

