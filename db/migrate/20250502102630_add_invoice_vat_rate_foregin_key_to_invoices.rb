class AddInvoiceVatRateForeginKeyToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :invoice_vat_rate_id, :integer
    remove_column :invoices, :vat, :integer
  end
end
