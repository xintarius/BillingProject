# company_properties_grid
class CompanyGrid
  include Datagrid

  scope do
    Company.all
  end

  column :id, header: -> { I18n.t('views.datagrid.companies.id') }, &:id
  column :nip, header: -> { I18n.t('views.datagrid.companies.nip') }, &:nip
  column :name, header: -> { I18n.t('views.datagrid.companies.name') }, &:name
  column :created_at, header: -> { I18n.t('views.datagrid.companies.created_at') } do |record|
    record.created_at.strftime('%d-%m-%Y %H:%M')
  end
  column :updated_at, header: -> { I18n.t('views.datagrid.companies.updated_at') } do |record|
    record.updated_at.strftime('%d-%m-%Y %H:%M')
  end
end
