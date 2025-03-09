class AddColumnsToInvoiceTable < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :invoice_nr, :string
    add_column :invoices, :image_pdf_created, :boolean, default: false
    add_column :invoices, :file_path, :string
    add_column :invoices, :invoice_status, :string, default: 'initial'
  end
end
