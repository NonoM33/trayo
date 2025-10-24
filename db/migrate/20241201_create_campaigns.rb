class CreateCampaigns < ActiveRecord::Migration[7.0]
  def change
    create_table :campaigns do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.boolean :is_active, default: true
      t.string :banner_color, default: '#3b82f6'
      t.string :popup_title, null: false
      t.text :popup_message, null: false

      t.timestamps
    end
    
    add_index :campaigns, [:is_active, :start_date, :end_date]
  end
end
