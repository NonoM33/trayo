class AddTransactionIdToWithdrawals < ActiveRecord::Migration[8.0]
  def change
    add_column :withdrawals, :transaction_id, :string
    add_index :withdrawals, :transaction_id
  end
end
