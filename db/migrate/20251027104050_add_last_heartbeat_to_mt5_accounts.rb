class AddLastHeartbeatToMt5Accounts < ActiveRecord::Migration[8.0]
  def change
    add_column :mt5_accounts, :last_heartbeat_at, :datetime
  end
end
