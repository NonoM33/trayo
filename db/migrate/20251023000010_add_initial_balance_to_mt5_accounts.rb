class AddInitialBalanceToMt5Accounts < ActiveRecord::Migration[8.0]
  def change
    add_column :mt5_accounts, :initial_balance, :decimal, precision: 15, scale: 2, default: 0.0
  end
end

