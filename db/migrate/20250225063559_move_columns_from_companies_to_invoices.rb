class MoveColumnsFromCompaniesToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :invoice_date, :datetime
    add_column :invoices, :brutto, :integer
    add_column :invoices, :vat, :integer
    add_column :invoices, :netto, :integer

    remove_column :companies, :invoice_date
    remove_column :companies, :brutto
    remove_column :companies, :vat
    remove_column :companies, :netto
  end
end
