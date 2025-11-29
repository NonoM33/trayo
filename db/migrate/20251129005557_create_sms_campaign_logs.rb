class CreateSmsCampaignLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sms_campaigns do |t|
      t.string :name, null: false
      t.string :sms_type
      t.text :message_template
      t.string :status, default: 'draft'
      t.string :target_audience
      t.text :target_filters
      t.integer :recipients_count, default: 0
      t.integer :sent_count, default: 0
      t.integer :failed_count, default: 0
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.datetime :completed_at
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :sms_campaigns, :status
    add_index :sms_campaigns, :scheduled_at

    create_table :sms_campaign_logs do |t|
      t.references :user, foreign_key: true
      t.references :sent_by, foreign_key: { to_table: :users }
      t.references :sms_campaign, foreign_key: true, null: true
      t.string :sms_type
      t.text :message
      t.string :phone_number
      t.string :status, default: 'sent'
      t.datetime :sent_at
      t.string :provider_message_id
      t.text :error_message

      t.timestamps
    end

    add_index :sms_campaign_logs, :sms_type
    add_index :sms_campaign_logs, :status
    add_index :sms_campaign_logs, :sent_at
  end
end
