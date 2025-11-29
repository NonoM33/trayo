class AddExternalIdToCommissionReminders < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:commission_reminders, :external_id)
      add_column :commission_reminders, :external_id, :string
    end
  end
end
