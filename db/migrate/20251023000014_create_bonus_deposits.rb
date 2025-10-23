class CreateBonusDeposits < ActiveRecord::Migration[8.0]
  def change
    create_table :bonus_deposits do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :bonus_percentage, precision: 5, scale: 2, null: false
      t.decimal :bonus_amount, precision: 15, scale: 2, null: false
      t.decimal :total_credit, precision: 15, scale: 2, null: false
      t.string :status, default: "pending", null: false
      t.text :notes
      t.timestamps
      
      t.index [:user_id, :created_at]
      t.index :status
    end
  end
end
