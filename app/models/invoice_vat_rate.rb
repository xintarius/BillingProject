# invoice vat type model
class InvoiceVatRate < ApplicationRecord
  has_many :invoices, dependent: :destroy

  self.table_name = 'invoice_vat_rates'
end
