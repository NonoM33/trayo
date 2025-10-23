class AddTrackingToBotsAndTrades < ActiveRecord::Migration[8.0]
  def change
    add_column :trading_bots, :symbol, :string
    add_column :trading_bots, :magic_number_prefix, :integer
    
    add_column :bot_purchases, :magic_number, :integer
    
    add_column :trades, :comment, :string
    add_column :trades, :magic_number, :integer
    
    add_index :trades, :comment
    add_index :trades, :magic_number
    add_index :bot_purchases, :magic_number
  end
end

