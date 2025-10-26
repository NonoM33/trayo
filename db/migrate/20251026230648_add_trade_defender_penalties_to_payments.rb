class AddTradeDefenderPenaltiesToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :trade_defender_penalties_snapshot, :text
  end
end
