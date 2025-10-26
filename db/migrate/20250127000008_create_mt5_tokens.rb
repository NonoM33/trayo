class CreateMt5Tokens < ActiveRecord::Migration[8.0]
  def change
    create_table :mt5_tokens do |t|
      t.string :token, null: false
      t.text :description
      t.string :client_name
      t.datetime :used_at

      t.timestamps
    end

    add_index :mt5_tokens, :token, unique: true
    add_index :mt5_tokens, :used_at
  end
end
