class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_subscription_id, null: false
      t.string :stripe_customer_id, null: false
      t.string :plan, null: false
      t.string :status, default: 'active'
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at
      t.decimal :monthly_price, precision: 10, scale: 2
      t.integer :failed_payment_count, default: 0
      t.datetime :last_payment_failed_at
      t.datetime :last_reminder_sent_at
      t.text :cancellation_reason

      t.timestamps
    end

    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, :stripe_customer_id
    add_index :subscriptions, :status
    add_index :subscriptions, :plan

    add_column :users, :stripe_customer_id, :string
    add_index :users, :stripe_customer_id
  end
end
