class AddWatermarkToMt5Accounts < ActiveRecord::Migration[8.0]
  def change
    add_column :mt5_accounts, :high_watermark, :decimal, precision: 15, scale: 2, default: 0.0
    add_column :mt5_accounts, :total_withdrawals, :decimal, precision: 15, scale: 2, default: 0.0
  end
end

