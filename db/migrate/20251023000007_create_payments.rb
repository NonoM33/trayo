class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.date :payment_date, null: false
      t.string :status, default: "pending", null: false
      t.string :reference
      t.text :notes

      t.timestamps
    end

    add_index :payments, :status
    add_index :payments, :payment_date
  end
end

