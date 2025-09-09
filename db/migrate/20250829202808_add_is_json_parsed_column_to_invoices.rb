class AddIsJsonParsedColumnToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :is_json_parsed, :boolean
  end
end
