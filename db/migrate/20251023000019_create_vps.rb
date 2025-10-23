class CreateVps < ActiveRecord::Migration[8.0]
  def change
    create_table :vps do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :ip_address
      t.string :server_location
      t.string :status, default: 'ordered'
      t.decimal :monthly_price, precision: 10, scale: 2, default: 0
      t.text :access_credentials
      t.text :notes
      t.datetime :ordered_at
      t.datetime :configured_at
      t.datetime :ready_at
      t.datetime :activated_at
      
      t.timestamps
    end
    
    add_index :vps, :status unless index_exists?(:vps, :status)
  end
end

