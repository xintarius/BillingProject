class AddUserToDailyInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :daily_invoices, :user_id, :integer
  end
end
