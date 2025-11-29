require 'open3'

class BackupService
  BACKUP_DIR = Rails.root.join('storage', 'backups')
  RETENTION_DAYS = 30

  class << self
    def create_backup(notes: nil)
      ensure_backup_directory
      
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      filename = "backup_#{timestamp}.sql"
      file_path = BACKUP_DIR.join(filename)
      
      backup = DatabaseBackup.create!(
        filename: filename,
        backup_date: Time.current,
        status: 'pending',
        notes: notes
      )

      begin
        config = ActiveRecord::Base.connection_db_config.configuration_hash
        database = config[:database] || ENV['DATABASE_NAME']
        username = config[:username] || ENV['DATABASE_USER'] || ENV['USER']
        host = config[:host] || 'localhost'
        port = config[:port] || 5432
        password = config[:password] || ENV['DATABASE_PASSWORD']

        env_vars = ENV.to_h.dup
        env_vars['PGPASSWORD'] = password if password.present?

        pg_dump_cmd = [
          'pg_dump',
          '-h', host,
          '-p', port.to_s,
          '-U', username,
          '-d', database,
          '-F', 'c',
          '-f', file_path.to_s,
          '--no-owner',
          '--no-acl'
        ]

        result = system(env_vars, *pg_dump_cmd)

        unless result
          raise "pg_dump failed with exit code #{$?.exitstatus}"
        end

        file_size = File.size(file_path)
        
        backup.update!(
          status: 'completed',
          file_size: file_size
        )

        cleanup_old_backups

        backup
      rescue => e
        backup.update!(
          status: 'failed',
          error_message: e.message
        )
        File.delete(file_path) if File.exist?(file_path)
        raise e
      end
    end

    def restore_backup(backup)
      unless backup.can_restore?
        raise "Backup cannot be restored: status=#{backup.status}, exists=#{backup.exists?}"
      end

      backup.update!(status: 'restoring')

      begin
        config = ActiveRecord::Base.connection_db_config.configuration_hash
        database = config[:database] || ENV['DATABASE_NAME']
        username = config[:username] || ENV['DATABASE_USER'] || ENV['USER']
        host = config[:host] || 'localhost'
        port = config[:port] || 5432
        password = config[:password] || ENV['DATABASE_PASSWORD']

        env_vars = ENV.to_h.dup
        env_vars['PGPASSWORD'] = password if password.present?

        pg_restore_cmd = [
          'pg_restore',
          '-h', host,
          '-p', port.to_s,
          '-U', username,
          '-d', database,
          '--clean',
          '--if-exists',
          '--no-owner',
          '--no-acl',
          '--single-transaction',
          backup.file_path.to_s
        ]

        stdout, stderr, status = Open3.capture3(env_vars, *pg_restore_cmd)
        
        Rails.logger.info "pg_restore stdout: #{stdout}" if stdout.present?
        Rails.logger.info "pg_restore stderr: #{stderr}" if stderr.present?
        Rails.logger.info "pg_restore exit status: #{status.exitstatus}"

        if status.exitstatus == 0 || (status.exitstatus == 1 && !stderr.include?('FATAL') && !stderr.include?('ERROR'))
          backup.update!(status: 'completed', error_message: nil)
          backup
        else
          error_lines = stderr.split("\n").select { |l| l.include?('ERROR') || l.include?('FATAL') }.first(5)
          error_msg = error_lines.any? ? error_lines.join("; ") : "pg_restore failed with exit code #{status.exitstatus}"
          raise error_msg
        end
      rescue => e
        backup.update!(
          status: 'failed',
          error_message: e.message
        )
        raise e
      end
    end

    def upload_backup(file, notes: nil)
      ensure_backup_directory

      unless file.respond_to?(:read)
        raise "Invalid file object"
      end

      original_filename = file.original_filename || file.path.split('/').last
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      filename = "uploaded_#{timestamp}_#{original_filename}"
      file_path = BACKUP_DIR.join(filename)

      if file.respond_to?(:tempfile) && File.exist?(file.tempfile.path)
        FileUtils.cp(file.tempfile.path, file_path)
      elsif file.respond_to?(:path) && File.exist?(file.path)
        FileUtils.cp(file.path, file_path)
      else
        File.open(file_path, 'wb') do |f|
          f.write(file.read)
        end
      end

      file_size = File.size(file_path)
      
      if file_size == 0
        File.delete(file_path) if File.exist?(file_path)
        raise "Le fichier téléversé est vide (0 bytes)"
      end

      backup = DatabaseBackup.create!(
        filename: filename,
        file_size: file_size,
        backup_date: Time.current,
        status: 'completed',
        notes: notes
      )

      backup
    rescue => e
      File.delete(file_path) if File.exist?(file_path)
      raise e
    end

    def cleanup_old_backups
      cutoff_date = RETENTION_DAYS.days.ago
      
      DatabaseBackup.where('created_at < ?', cutoff_date).find_each do |backup|
        if backup.exists?
          File.delete(backup.file_path) rescue nil
        end
        backup.destroy
      end
    end

    private

    def ensure_backup_directory
      FileUtils.mkdir_p(BACKUP_DIR) unless Dir.exist?(BACKUP_DIR)
    end
  end
end

