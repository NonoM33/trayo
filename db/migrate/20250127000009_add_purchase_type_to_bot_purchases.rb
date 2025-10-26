class AddPurchaseTypeToBotPurchases < ActiveRecord::Migration[7.0]
  def change
    add_column :bot_purchases, :purchase_type, :string, default: 'manual'
    add_index :bot_purchases, :purchase_type
  end
end
