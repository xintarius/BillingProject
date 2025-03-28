class CreateDailyInvoice < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_invoices do |t|

      t.date :date, null: false
      t.integer :invoice_count
      t.integer :brutto_count
      t.integer :netto_count

      t.timestamps
    end
  end
end
