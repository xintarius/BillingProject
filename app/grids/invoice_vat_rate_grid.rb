# InvoiceVatRatesGrid
class InvoiceVatRateGrid
  include Datagrid

  scope do
    InvoiceVatRate.all
  end

  column :id, header: -> { I18n.t('views.datagrid.vat_rates.id') }, &:id
  column :vat_rate, header: -> { I18n.t('views.datagrid.vat_rates.vat') } do |record|
    "#{record.vat_rate.to_i}%"
  end

  column :created_at, header: -> { I18n.t('views.datagrid.vat_rates.created_at') }, &:created_at
  column :updated_at, header: -> { I18n.t('views.datagrid.vat_rates.updated_at') }, &:updated_at
end
