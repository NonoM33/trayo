class CreateCreditPacks < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_packs do |t|
      t.integer :amount
      t.integer :bonus_percentage
      t.string :label
      t.boolean :is_popular
      t.boolean :is_best
      t.boolean :active
      t.integer :position

      t.timestamps
    end
  end
end
