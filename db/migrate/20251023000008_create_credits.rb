class CreateCredits < ActiveRecord::Migration[8.0]
  def change
    create_table :credits do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.text :reason

      t.timestamps
    end

    add_index :credits, :created_at
  end
end

