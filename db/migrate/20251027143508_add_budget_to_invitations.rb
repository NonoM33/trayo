class AddBudgetToInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :invitations, :budget, :decimal
  end
end
