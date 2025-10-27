class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :code, null: false
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :status, default: "pending"
      t.datetime :used_at
      t.datetime :expires_at
      t.text :broker_data
      t.text :broker_credentials
      t.text :selected_bots
      t.integer :step, default: 1
      
      t.timestamps
    end
    
    add_index :invitations, :code, unique: true
    add_index :invitations, :status
  end
end
