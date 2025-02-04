class CreateTableCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :nip
      t.datetime :invoice_date
      t.integer :brutto
      t.integer :netto
      t.integer :vat

      t.timestamps
    end
  end
end
