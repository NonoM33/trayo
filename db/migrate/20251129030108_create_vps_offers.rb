class CreateVpsOffers < ActiveRecord::Migration[8.0]
  def change
    create_table :vps_offers do |t|
      t.string :name
      t.decimal :price
      t.string :specs
      t.text :description
      t.boolean :is_recommended
      t.boolean :active
      t.integer :position

      t.timestamps
    end
  end
end
