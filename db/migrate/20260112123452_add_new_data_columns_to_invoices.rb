class AddNewDataColumnsToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :user_nip_data, :string
    add_column :invoices, :company_nip_data, :string
    add_column :invoices, :vat_type_data, :numeric
  end
end
