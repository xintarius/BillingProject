# export_grid
class ExportGrid
  include Datagrid

  scope do
    Export.all
  end

  column :id, &:id
  column :export_name, &:export_name
  column :subject, &:subject
  column :export_type, &:export_type
  column :user_id, &:user_id
  column :created_at, &:created_at
end
