class AddContentColumnToExports < ActiveRecord::Migration[8.0]
  def change
    add_column :exports, :content, :binary
  end
end
