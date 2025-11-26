class AddMessageContentToCommissionReminders < ActiveRecord::Migration[8.0]
  def change
    add_column :commission_reminders, :message_content, :text
  end
end

