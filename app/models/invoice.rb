# invoice model
class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :invoice_types
end
