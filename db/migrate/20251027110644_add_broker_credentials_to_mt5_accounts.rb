class AddBrokerCredentialsToMt5Accounts < ActiveRecord::Migration[8.0]
  def change
    add_column :mt5_accounts, :broker_name, :string
    add_column :mt5_accounts, :broker_server, :string
    add_column :mt5_accounts, :broker_password, :string
  end
end
