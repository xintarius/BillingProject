# role_grid
class RoleGrid
  include Datagrid

  scope do
    Role.all
  end

  column :id, header: -> { I18n.t('views.datagrid.roles.id') }, &:id
  column :name, header: -> { I18n.t('views.datagrid.roles.name') }, &:name
  column :code, header: -> { I18n.t('views.datagrid.roles.code') }, &:code
end
