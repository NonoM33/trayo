class AddAutoCalculatedFieldsToMt5Accounts < ActiveRecord::Migration[8.0]
  def change
    add_column :mt5_accounts, :auto_calculated_initial_balance, :boolean, default: false, null: false
    add_column :mt5_accounts, :calculated_initial_balance, :decimal, precision: 15, scale: 2
    add_column :mt5_accounts, :total_deposits, :decimal, precision: 15, scale: 2, default: 0.0
  end
end
