class CreateWithdrawals < ActiveRecord::Migration[8.0]
  def change
    create_table :withdrawals do |t|
      t.references :mt5_account, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.datetime :withdrawal_date, null: false

      t.timestamps
    end

    add_index :withdrawals, :withdrawal_date
  end
end

