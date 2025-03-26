class AddDescriptionErrorColumnToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :description_error, :string
  end
end
