class AddCampaignTypeAndBanners < ActiveRecord::Migration[8.0]
  def change
    add_column :sms_campaigns, :campaign_type, :string, default: 'sms'
    add_column :sms_campaigns, :email_subject, :string
    add_column :sms_campaigns, :email_body, :text
    add_column :sms_campaigns, :channels, :string, default: 'sms'
    
    add_index :sms_campaigns, :campaign_type

    create_table :banners do |t|
      t.string :title, null: false
      t.text :content
      t.string :banner_type, default: 'info'
      t.string :icon
      t.string :background_color
      t.string :text_color
      t.string :button_text
      t.string :button_url
      t.string :target_audience, default: 'all'
      t.text :target_filters
      t.boolean :is_dismissible, default: true
      t.boolean :is_active, default: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :priority, default: 0
      t.integer :views_count, default: 0
      t.integer :clicks_count, default: 0
      t.integer :dismissals_count, default: 0
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :banners, :banner_type
    add_index :banners, :is_active
    add_index :banners, :target_audience
    add_index :banners, [:starts_at, :ends_at]

    create_table :banner_dismissals do |t|
      t.references :banner, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :dismissed_at

      t.timestamps
    end

    add_index :banner_dismissals, [:banner_id, :user_id], unique: true
  end
end
