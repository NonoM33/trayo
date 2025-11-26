class CreateTicketComments < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_comments do |t|
      t.references :support_ticket, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.text :content, null: false
      t.boolean :is_internal, default: false
      t.string :author_name
      t.string :author_email

      t.timestamps
    end

    add_index :ticket_comments, :created_at
    add_index :ticket_comments, :is_internal
  end
end
