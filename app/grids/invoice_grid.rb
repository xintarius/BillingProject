# invoice grid
class InvoiceGrid
  include Datagrid

  scope do
    Invoice.order(id: :desc)
  end
  column :id, &:id
  column :invoice_nr, &:invoice_nr
  column :name, &:name

  column :invoice_date do |record|
    record.invoice_date.strftime('%Y-%m-%d') if record.invoice_date.present?
  end

  column :brutto, header: 'Brutto' do |record|
    "#{record.brutto} zł"
  end

  column :vat, header: 'Vat' do |record|
    "#{record.vat}%"
  end

  column :netto, header: 'Netto' do |record|
    "#{record.netto} zł"
  end

  column :created_at do |record|
    record.created_at.strftime('%Y-%m-%d %H:%M')
  end

  column(:invoice_status, order: false) do |record|
    ApplicationController.helpers.status_icon(record.invoice_status)
  end
end
