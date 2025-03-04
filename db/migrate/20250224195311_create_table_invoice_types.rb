class CreateTableInvoiceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_types do |t|
      t.string :type
      t.string :code
      t.timestamps
    end
  end
end
