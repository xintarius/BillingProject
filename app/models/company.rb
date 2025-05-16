# company model
class Company < ApplicationRecord
  has_many :invoices, dependent: :destroy
  has_many :users, through: :members
  before_save :normalize_nip

  private

  def normalize_nip
    self.nip = nip.gsub(/[-\s]/, '') if nip.present?
  end
end
