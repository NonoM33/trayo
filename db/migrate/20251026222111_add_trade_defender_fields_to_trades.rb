class AddTradeDefenderFieldsToTrades < ActiveRecord::Migration[8.0]
  def change
    add_column :trades, :trade_originality, :string, default: 'unknown'
    add_column :trades, :is_unauthorized_manual, :boolean, default: false
    
    add_index :trades, :trade_originality
    add_index :trades, :is_unauthorized_manual
  end
end
