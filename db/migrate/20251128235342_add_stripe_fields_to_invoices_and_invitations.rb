class AddStripeFieldsToInvoicesAndInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :stripe_payment_intent_id, :string
    add_column :invoices, :stripe_customer_id, :string
    add_column :invoices, :stripe_charge_id, :string
    add_index :invoices, :stripe_payment_intent_id

    add_column :invitations, :stripe_payment_intent_id, :string
    add_index :invitations, :stripe_payment_intent_id
  end
end
