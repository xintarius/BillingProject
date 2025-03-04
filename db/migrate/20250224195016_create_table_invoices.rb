class CreateTableInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :name
      t.references :company
      t.references :invoice_types
      t.timestamps
    end
  end
end
