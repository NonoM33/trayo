class CreateDatabaseBackups < ActiveRecord::Migration[8.0]
  def change
    create_table :database_backups do |t|
      t.string :filename, null: false
      t.bigint :file_size
      t.string :status, default: 'pending', null: false
      t.text :error_message
      t.text :notes
      t.datetime :backup_date, null: false

      t.timestamps
    end

    add_index :database_backups, :status
    add_index :database_backups, :backup_date
    add_index :database_backups, :created_at
  end
end

