class AddExternalIdToCommissionReminders < ActiveRecord::Migration[8.0]
  def change
    add_column :commission_reminders, :external_id, :string
  end
end
