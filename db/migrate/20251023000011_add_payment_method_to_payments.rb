class AddPaymentMethodToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :payment_method, :string
  end
end

