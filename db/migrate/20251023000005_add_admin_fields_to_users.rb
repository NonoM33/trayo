class AddAdminFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :commission_rate, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :users, :is_admin, :boolean, default: false
  end
end

