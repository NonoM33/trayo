class CreateInvoicesAndBillingFields < ActiveRecord::Migration[8.0]
  class MigrationBotPurchase < ActiveRecord::Base
    self.table_name = "bot_purchases"
  end

  class MigrationVps < ActiveRecord::Base
    self.table_name = "vps"
  end

  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :reference, null: false
      t.string :status, null: false, default: "pending"
      t.decimal :total_amount, precision: 15, scale: 2, default: 0
      t.decimal :balance_due, precision: 15, scale: 2, default: 0
      t.string :source
      t.date :due_date
      t.boolean :vps_included, default: true
      t.jsonb :metadata
      t.timestamps
    end

    add_index :invoices, :reference, unique: true

    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :label, null: false
      t.string :item_type
      t.bigint :item_id
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 15, scale: 2, default: 0
      t.decimal :total_price, precision: 15, scale: 2, default: 0
      t.jsonb :metadata
      t.timestamps
    end

    add_index :invoice_items, [:item_type, :item_id]

    create_table :invoice_payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.datetime :paid_at, null: false
      t.string :payment_method
      t.text :notes
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    change_table :bot_purchases do |t|
      t.references :invoice, foreign_key: true
      t.string :billing_status, null: false, default: "paid"
    end

    change_table :vps do |t|
      t.references :invoice, foreign_key: true
      t.string :billing_status, null: false, default: "paid"
    end

    reversible do |dir|
      dir.up do
        MigrationBotPurchase.update_all(billing_status: "paid")
        MigrationVps.update_all(billing_status: "paid")
      end
    end
  end
end

