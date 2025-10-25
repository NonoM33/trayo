class AddInitMt5ToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :init_mt5, :boolean, default: false, null: false
    add_index :users, :init_mt5
  end
end
