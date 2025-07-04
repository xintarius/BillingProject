class AddUserIdColumnToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :user_id, :integer
  end
end
