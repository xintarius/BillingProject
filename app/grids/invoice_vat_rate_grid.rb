# InvoiceVatRatesGrid
class InvoiceVatRateGrid
  include Datagrid

  scope do
    InvoiceVatRate.all
  end

  column :id, &:id
  column :vat_rate, header: 'Vat' do |record|
    "#{record.vat_rate.to_i}%"
  end

  column :created_at, &:created_at
  column :updated_at, &:updated_at
end
