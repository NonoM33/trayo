class CreateDeposits < ActiveRecord::Migration[8.0]
  def change
    create_table :deposits do |t|
      t.references :mt5_account, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.datetime :deposit_date, null: false
      t.string :transaction_id
      t.text :notes

      t.timestamps
    end

    add_index :deposits, :deposit_date
    add_index :deposits, :transaction_id
  end
end
