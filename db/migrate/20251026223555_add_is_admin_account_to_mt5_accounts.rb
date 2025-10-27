class AddIsAdminAccountToMt5Accounts < ActiveRecord::Migration[8.0]
  def change
    add_column :mt5_accounts, :is_admin_account, :boolean, default: false
    
    add_index :mt5_accounts, :is_admin_account
  end
end
