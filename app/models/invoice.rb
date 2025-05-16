# invoice model
class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :invoice_type
  belongs_to :invoice_vat_rate
  belongs_to :user
  attr_accessor :nip
end
