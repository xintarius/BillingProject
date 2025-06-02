# user_grid
class UserGrid
  include Datagrid

  scope do
    User.all
  end

  column :id, header: -> { I18n.t('views.datagrid.users.id') }, &:id
  column :email, header: -> { I18n.t('views.datagrid.users.email') }, &:email
  column :created_at, header: -> { I18n.t('views.datagrid.users.created_at') }, &:created_at
  column :updated_at, header: -> { I18n.t('views.datagrid.users.updated_at') }, &:updated_at
  column :role_id, header: -> { I18n.t('views.datagrid.users.role') } do |record|
    record.role&.name
  end
end
