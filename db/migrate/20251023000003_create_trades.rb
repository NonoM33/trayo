class CreateTrades < ActiveRecord::Migration[8.0]
  def change
    create_table :trades do |t|
      t.references :mt5_account, null: false, foreign_key: true
      t.string :trade_id, null: false
      t.string :symbol
      t.string :trade_type
      t.decimal :volume, precision: 15, scale: 5
      t.decimal :open_price, precision: 15, scale: 5
      t.decimal :close_price, precision: 15, scale: 5
      t.decimal :profit, precision: 15, scale: 2
      t.decimal :commission, precision: 15, scale: 2
      t.decimal :swap, precision: 15, scale: 2
      t.datetime :open_time
      t.datetime :close_time
      t.string :status

      t.timestamps
    end

    add_index :trades, [:mt5_account_id, :trade_id], unique: true
    add_index :trades, :close_time
    add_index :trades, :open_time
  end
end

