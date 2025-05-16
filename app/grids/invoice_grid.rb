# invoice grid
class InvoiceGrid
  include Datagrid
  attr_accessor :current_user

  scope do
    Invoice.all
  end

  column :id, if: ->(grid) { grid.current_user&.admin? }, &:id
  column :invoice_nr, &:invoice_nr
  column :name, order: false, &:name

  column :invoice_date do |record|
    record.invoice_date.strftime('%Y-%m-%d') if record.invoice_date.present?
  end

  column :brutto, order: false, header: 'Brutto' do |record|
    "#{record.brutto.to_f / 100} zł"
  end

  column :invoice_vat_rate_id, order: false, header: 'Vat' do |record|
    "#{record.invoice_vat_rate&.vat_rate.to_i}%"
  end

  column :netto, order: false, header: 'Netto' do |record|
    "#{record.netto.to_f / 100} zł"
  end

  column :created_at do |record|
    record.created_at.strftime('%Y-%m-%d %H:%M')
  end

  column(:invoice_status, order: false, class: 'invoice-status') do |record|
    ApplicationController.helpers.status_icon(record.invoice_status)
  end

  column :id, header: 'Podsumowanie Faktur', html: true, order: false do |record|
    button_to 'Sprawdź fakturę', Rails.application.routes.url_helpers.invoice_path(record), method: :get
  end
end
