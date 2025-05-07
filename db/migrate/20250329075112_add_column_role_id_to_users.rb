class AddColumnRoleIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role_id, :integer
  end
end
