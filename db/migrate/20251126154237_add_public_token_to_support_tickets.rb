class AddPublicTokenToSupportTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :support_tickets, :public_token, :string
    add_index :support_tickets, :public_token, unique: true
  end
end
