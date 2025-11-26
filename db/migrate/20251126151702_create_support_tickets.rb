class CreateSupportTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :support_tickets do |t|
      t.references :user, null: true, foreign_key: true
      t.string :phone_number, null: false
      t.string :status, null: false, default: "open"
      t.string :ticket_number, null: false
      t.text :subject
      t.text :description, null: false
      t.string :sms_message_id
      t.string :created_via, default: "sms"

      t.timestamps
    end

    add_index :support_tickets, :ticket_number, unique: true
    add_index :support_tickets, :status
    add_index :support_tickets, :phone_number
    add_index :support_tickets, :created_at
  end
end
