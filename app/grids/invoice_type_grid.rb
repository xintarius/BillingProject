# invoice_type_grid
class InvoiceTypeGrid
  include Datagrid

  scope do
    InvoiceType.all
  end

  column :id, &:id
  column :invoice_type, &:invoice_type
  column :code, &:code
  column :created_at, &:created_at
  column :updated_at, &:updated_at
end
