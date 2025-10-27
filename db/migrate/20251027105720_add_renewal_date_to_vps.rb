class AddRenewalDateToVps < ActiveRecord::Migration[8.0]
  def change
    add_column :vps, :renewal_date, :date
  end
end
