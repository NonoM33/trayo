class CreateBonusPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :bonus_periods do |t|
      t.decimal :bonus_percentage, precision: 5, scale: 2, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :active, default: true, null: false
      t.string :name
      t.text :description
      t.timestamps
      
      t.index :start_date
      t.index :end_date
      t.index :active
    end
  end
end

