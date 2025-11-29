class AddCommissionBillingFields < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :commission_billing_enabled, :boolean, default: true
    add_column :users, :last_commission_billing_date, :datetime
    add_column :users, :last_watermark_snapshot, :decimal, precision: 15, scale: 2
    add_column :users, :commission_balance_due, :decimal, precision: 15, scale: 2, default: 0
    add_column :users, :commission_payment_failed, :boolean, default: false
    add_column :users, :commission_payment_failed_at, :datetime
    add_column :users, :bots_suspended_for_payment, :boolean, default: false

    add_column :mt5_accounts, :watermark_at_last_billing, :decimal, precision: 15, scale: 2
    add_column :mt5_accounts, :initial_balance_snapshot, :decimal, precision: 15, scale: 2

    create_table :commission_invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :invoice, foreign_key: true
      t.string :reference, null: false
      t.string :period_type
      t.date :period_start
      t.date :period_end
      t.decimal :total_profit, precision: 15, scale: 2, default: 0
      t.decimal :commission_rate, precision: 5, scale: 2
      t.decimal :commission_amount, precision: 15, scale: 2, default: 0
      t.decimal :late_fee, precision: 15, scale: 2, default: 0
      t.decimal :total_amount, precision: 15, scale: 2, default: 0
      t.string :status, default: 'pending'
      t.string :stripe_payment_intent_id
      t.datetime :due_date
      t.datetime :paid_at
      t.datetime :reminder_sent_at
      t.text :notes

      t.timestamps
    end

    add_index :commission_invoices, :reference, unique: true
    add_index :commission_invoices, :status
    add_index :commission_invoices, :due_date
  end
end
