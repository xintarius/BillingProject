# company_properties_grid
class CompanyGrid
  include Datagrid

  scope do
    Company.all
  end

  column :id, &:id
  column :nip, &:nip
  column :name, header: 'Nazwa Firmy', &:name
  column :created_at, header: 'Data Utworzenia' do |record|
    record.created_at.strftime('%d-%m-%Y %H:%M')
  end
  column :updated_at, header: 'Zmodyfikowano' do |record|
    record.updated_at.strftime('%d-%m-%Y %H:%M')
  end
end
