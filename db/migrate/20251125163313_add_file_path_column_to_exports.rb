class AddFilePathColumnToExports < ActiveRecord::Migration[8.0]
  def change
    add_column :exports, :file_path, :string
  end
end
