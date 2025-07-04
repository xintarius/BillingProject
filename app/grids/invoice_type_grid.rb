# invoice_type_grid
class InvoiceTypeGrid
  include Datagrid

  scope do
    InvoiceType.all
  end

  column :id, header: -> { I18n.t('views.datagrid.invoice_types.id') }, &:id
  column :invoice_type, header: -> { I18n.t('views.datagrid.invoice_types.invoice_type') }, &:invoice_type
  column :code, header: -> { I18n.t('views.datagrid.invoice_types.code') }, &:code
  column :created_at, header: -> { I18n.t('views.datagrid.invoice_types.created_at') }, &:created_at
  column :updated_at, header: -> { I18n.t('views.datagrid.invoice_types.updated_at') }, &:updated_at
end
