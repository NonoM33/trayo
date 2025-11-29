class CreateScheduledSms < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduled_sms do |t|
      t.references :user, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.text :message, null: false
      t.string :sms_type
      t.string :phone_number
      t.datetime :scheduled_at, null: false
      t.string :status, default: 'pending'
      t.datetime :sent_at
      t.text :error_message

      t.timestamps
    end

    add_index :scheduled_sms, :scheduled_at
    add_index :scheduled_sms, :status
  end
end
