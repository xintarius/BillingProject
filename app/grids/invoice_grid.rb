# invoice grid
class InvoiceGrid
  include Datagrid
  attr_accessor :current_user

  scope do
    Invoice.all
  end

  column :id, header: -> { I18n.t('views.datagrid.invoices.id') }, if: ->(grid) { grid.current_user&.admin? }, &:id
  column :invoice_nr, header: -> { I18n.t('views.datagrid.invoices.invoice_nr') }, &:invoice_nr
  column :name, header: -> { I18n.t('views.datagrid.invoices.name') }, order: false, &:name

  column :invoice_date, header: -> { I18n.t('views.datagrid.invoices.invoice_date') } do |record|
    record.invoice_date.strftime('%Y-%m-%d') if record.invoice_date.present?
  end

  column :brutto, header: -> { I18n.t('views.datagrid.invoices.gross') }, order: false do |record|
    "#{record.brutto.to_f / 100} zł"
  end

  column :invoice_vat_rate_id, header: -> { I18n.t('views.datagrid.invoices.vat') }, order: false do |record|
    "#{record.invoice_vat_rate&.vat_rate.to_i}%"
  end

  column :netto, header: -> { I18n.t('views.datagrid.invoices.net') }, order: false do |record|
    "#{record.netto.to_f / 100} zł"
  end

  column :created_at, header: -> { I18n.t('views.datagrid.invoices.created_at') } do |record|
    record.created_at.strftime('%Y-%m-%d %H:%M')
  end

  column(:invoice_status, header: -> { I18n.t('views.datagrid.invoices.invoice_status') }, order: false, class: 'invoice-status') do |record|
    ApplicationController.helpers.status_icon(record.invoice_status)
  end

  column :id, header: -> { I18n.t('views.datagrid.invoices.invoice_summary') }, html: true, order: false do |record|
    button_to I18n.t('views.datagrid.invoices.check_invoice'),
              Rails.application.routes.url_helpers.invoice_path(id: record.id, locale: params[:locale]), method: :get
  end
end
