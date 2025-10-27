class AddManualWatermarkToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :manual_watermark, :decimal, precision: 15, scale: 2
  end
end
