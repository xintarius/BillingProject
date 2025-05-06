# invoice vat type model
class InvoiceVatRate < ApplicationRecord
  has_many :invoices, dependent: :destroy
end
