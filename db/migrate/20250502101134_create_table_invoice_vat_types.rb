class CreateTableInvoiceVatTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_vat_rates do |t|
      t.decimal :vat_rate, :precision => 5, :scale => 1
      t.string :comment
      t.timestamps
    end
  end
end
