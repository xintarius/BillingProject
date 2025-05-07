# user_grid
class UserGrid
  include Datagrid

  scope do
    User.all
  end

  column :id, &:id
  column :email, &:email
  column :created_at, &:created_at
  column :updated_at, &:updated_at
  column :role_id, header: 'Rola' do |record|
    record.role&.name
  end
end
