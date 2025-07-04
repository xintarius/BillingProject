# export_grid
class ExportGrid
  include Datagrid

  scope do
    Export.all
  end

  column :id, header: -> { I18n.t('views.datagrid.exports.id') }, &:id
  column :export_name, header: -> { I18n.t('views.datagrid.exports.export_name') }, &:export_name
  column :subject, header: -> { I18n.t('views.datagrid.exports.subject') }, &:subject
  column :export_type, header: -> { I18n.t('views.datagrid.exports.export_type') }, &:export_type
  column :user_id, header: -> { I18n.t('views.datagrid.exports.user') }, &:user_id
  column :created_at, header: -> { I18n.t('views.datagrid.exports.created_at') }, &:created_at
end
