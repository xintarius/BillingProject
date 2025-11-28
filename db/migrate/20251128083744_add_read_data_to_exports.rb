class AddReadDataToExports < ActiveRecord::Migration[8.0]
  def change
    add_column :exports, :read_data, :binary
  end
end
