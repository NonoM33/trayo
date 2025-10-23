class AddWatermarkSnapshotToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :watermark_snapshot, :text
  end
end

