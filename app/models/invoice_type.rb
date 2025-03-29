# invoice_type model
class InvoiceType < ApplicationRecord
  has_many :invoice, dependent: :destroy

  self.table_name = 'invoice_types'
end
