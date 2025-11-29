class CreateShopProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_products do |t|
      t.string :name, null: false
      t.text :description
      t.string :product_type, null: false, default: 'subscription'
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :stripe_price_id
      t.string :stripe_product_id
      t.text :features
      t.string :interval, default: 'year'
      t.boolean :active, default: true
      t.integer :position, default: 0
      t.string :icon, default: 'fa-box'
      t.string :badge
      t.string :badge_color

      t.timestamps
    end

    add_index :shop_products, :product_type
    add_index :shop_products, :active
    add_index :shop_products, :position

    create_table :product_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shop_product, null: false, foreign_key: true
      t.decimal :price_paid, precision: 10, scale: 2, null: false
      t.string :status, default: 'pending'
      t.string :stripe_payment_intent_id
      t.string :stripe_subscription_id
      t.datetime :expires_at
      t.datetime :starts_at

      t.timestamps
    end

    add_index :product_purchases, :status
    add_index :product_purchases, :stripe_payment_intent_id
    add_index :product_purchases, :stripe_subscription_id
  end
end
