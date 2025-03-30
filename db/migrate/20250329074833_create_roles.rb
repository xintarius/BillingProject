class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :description
      t.timestamps
    end
  end
end
