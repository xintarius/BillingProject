class CreateTableAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.string :city
      t.string :postal_code
      t.string :street
      t.string :building
      t.string :apartment
      t.string :postal_city
      t.timestamps
    end
  end
end
