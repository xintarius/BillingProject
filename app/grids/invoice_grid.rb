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
  column :brutto, &:brutto
  column :vat, &:vat
  column :netto, &:netto
  column :created_at do |record|
    record.created_at.strftime('%Y-%m-%d %H:%M')
  end
end
