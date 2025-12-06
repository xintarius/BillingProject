class RenameAndAddColumnToInvoices < ActiveRecord::Migration[8.0]
  def change
    rename_column :invoices, :invoice_data, :azure_invoice_raw_data
    add_column :invoices, :parsed_azure_invoice_data, :jsonb
  end
end
