class AddMemberIdColumnToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :member_id, :integer
  end
end
