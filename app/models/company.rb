# company model
class Company < ApplicationRecord
  has_many :invoices, dependent: :destroy
end
