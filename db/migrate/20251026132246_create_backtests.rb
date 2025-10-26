class CreateBacktests < ActiveRecord::Migration[8.0]
  def change
    create_table :backtests do |t|
      t.references :trading_bot, null: false, foreign_key: true
      t.datetime :start_date
      t.datetime :end_date
      t.integer :total_trades
      t.integer :winning_trades
      t.integer :losing_trades
      t.decimal :total_profit, precision: 15, scale: 2
      t.decimal :max_drawdown, precision: 10, scale: 2
      t.decimal :win_rate, precision: 5, scale: 2
      t.decimal :average_profit, precision: 15, scale: 2
      t.decimal :projection_monthly_min, precision: 15, scale: 2
      t.decimal :projection_monthly_max, precision: 15, scale: 2
      t.decimal :projection_yearly, precision: 15, scale: 2
      t.string :file_path
      t.string :original_filename
      t.boolean :is_active, default: false

      t.timestamps
    end
    
    add_index :backtests, :is_active
  end
end
