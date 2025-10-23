class CreateMt5Accounts < ActiveRecord::Migration[8.0]
  def change
    create_table :mt5_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :mt5_id, null: false
      t.string :account_name, null: false
      t.decimal :balance, precision: 15, scale: 2, default: 0.0
      t.datetime :last_sync_at

      t.timestamps
    end

    add_index :mt5_accounts, :mt5_id, unique: true
    add_index :mt5_accounts, [:user_id, :mt5_id], unique: true
  end
end

