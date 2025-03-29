# invoice model
class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :invoice_type

  attr_accessor :nip
end
