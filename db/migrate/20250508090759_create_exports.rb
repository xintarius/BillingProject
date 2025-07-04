class CreateExports < ActiveRecord::Migration[8.0]
  def change
    create_table :exports do |t|
      t.string :export_name
      t.string :subject
      t.text :params
      t.string :error_messages
      t.text :read_data
      t.string :export_type
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
