class CreateTableLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.references :company, foreign_key: true
      t.references :addresses, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
