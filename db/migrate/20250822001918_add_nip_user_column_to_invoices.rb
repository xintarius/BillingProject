class AddNipUserColumnToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :user_nip, :string, default: false
  end
end
