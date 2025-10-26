class AddButtonFieldsToCampaigns < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:campaigns, :button_text)
      add_column :campaigns, :button_text, :string, limit: 255
    end
    
    unless column_exists?(:campaigns, :button_url)
      add_column :campaigns, :button_url, :string, limit: 255
    end
  end
end

