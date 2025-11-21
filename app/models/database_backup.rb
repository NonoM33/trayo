class DatabaseBackup < ApplicationRecord
  STATUSES = %w[pending completed failed restoring].freeze

  validates :filename, presence: true
  validates :backup_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :pending, -> { where(status: 'pending') }
  scope :restoring, -> { where(status: 'restoring') }

  def file_path
    Rails.root.join('storage', 'backups', filename)
  end

  def exists?
    File.exist?(file_path)
  end

  def file_size_human
    return '0 B' unless file_size
    units = ['B', 'KB', 'MB', 'GB']
    size = file_size.to_f
    unit_index = 0
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    "#{size.round(2)} #{units[unit_index]}"
  end

  def pending?
    status == 'pending'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def restoring?
    status == 'restoring'
  end

  def can_restore?
    completed? && exists?
  end
end

