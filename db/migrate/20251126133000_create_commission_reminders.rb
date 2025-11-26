class CreateCommissionReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :commission_reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false, default: "initial"
      t.decimal :amount, precision: 15, scale: 2, default: 0
      t.decimal :watermark_reference, precision: 15, scale: 2, default: 0
      t.string :phone_number
      t.string :status, null: false, default: "pending"
      t.string :external_id
      t.datetime :deadline_at
      t.datetime :sent_at
      t.text :response_payload
      t.text :error_message

      t.timestamps
    end

    add_index :commission_reminders, [:user_id, :kind, :created_at], name: "idx_commission_reminders_user_kind_created"
  end
end

