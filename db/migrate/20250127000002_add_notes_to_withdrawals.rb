class AddNotesToWithdrawals < ActiveRecord::Migration[8.0]
  def change
    add_column :withdrawals, :notes, :text
    add_column :withdrawals, :status, :string, default: 'completed'
  end
end
