class AddDataColumnsToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :invoice_data_brutto, :integer
    add_column :invoices, :invoice_data_netto, :integer
    add_column :invoices, :invoice_data_nr, :string
    add_column :invoices, :invoice_data_date, :timestamp
  end
end
