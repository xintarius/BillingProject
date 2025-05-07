# role_grid
class RoleGrid
  include Datagrid

  scope do
    Role.all
  end

  column :id, &:id
  column :name, &:name
  column :code, &:code
end
