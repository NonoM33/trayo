class AddApiTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :mt5_api_token, :string
    add_index :users, :mt5_api_token, unique: true
  end
end

