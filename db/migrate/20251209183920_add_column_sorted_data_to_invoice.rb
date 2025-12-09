class AddColumnSortedDataToInvoice < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :sorted_data, :jsonb
  end
end
