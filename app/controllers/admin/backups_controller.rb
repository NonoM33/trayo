module Admin
  class BackupsController < BaseController
    before_action :require_admin
    before_action :set_backup, only: [:show, :destroy, :restore, :download]

    def index
      @backups = DatabaseBackup.recent.page(params[:page]).per(20)
    end

    def show
    end

    def create
      notes = params[:notes]
      
      begin
        @backup = BackupService.create_backup(notes: notes)
        redirect_to admin_backups_path, notice: "Backup créé avec succès: #{@backup.filename}"
      rescue => e
        Rails.logger.error "Backup creation failed: #{e.message}"
        redirect_to admin_backups_path, alert: "Erreur lors de la création du backup: #{e.message}"
      end
    end

    def upload
      unless params[:file].present?
        redirect_to admin_backups_path, alert: "Aucun fichier sélectionné"
        return
      end

      begin
        @backup = BackupService.upload_backup(
          params[:file],
          notes: params[:notes]
        )
        redirect_to admin_backups_path, notice: "Backup téléversé avec succès: #{@backup.filename}"
      rescue => e
        Rails.logger.error "Backup upload failed: #{e.message}"
        redirect_to admin_backups_path, alert: "Erreur lors du téléversement: #{e.message}"
      end
    end

    def restore
      unless @backup.can_restore?
        redirect_to admin_backups_path, alert: "Ce backup ne peut pas être restauré"
        return
      end

      unless params[:confirm] == 'yes'
        redirect_to admin_backup_path(@backup), 
          alert: "Vous devez confirmer la restauration. Cette opération va remplacer toutes les données actuelles !"
        return
      end

      begin
        BackupService.restore_backup(@backup)
        redirect_to admin_backups_path, notice: "Backup restauré avec succès. La base de données a été restaurée à l'état du #{@backup.backup_date.strftime('%d/%m/%Y à %H:%M')}"
      rescue => e
        Rails.logger.error "Backup restore failed: #{e.message}"
        redirect_to admin_backup_path(@backup), alert: "Erreur lors de la restauration: #{e.message}"
      end
    end

    def download
      unless @backup.exists?
        redirect_to admin_backups_path, alert: "Le fichier de backup n'existe plus"
        return
      end

      send_file @backup.file_path,
        filename: @backup.filename,
        type: 'application/octet-stream',
        disposition: 'attachment'
    end

    def destroy
      if @backup.exists?
        File.delete(@backup.file_path) rescue nil
      end
      
      @backup.destroy
      redirect_to admin_backups_path, notice: "Backup supprimé avec succès"
    end

    private

    def set_backup
      @backup = DatabaseBackup.find(params[:id])
    end
  end
end

