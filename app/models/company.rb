# company model
class Company < ApplicationRecord
  has_many :invoices, dependent: :destroy
  has_many :users, through: :members
  before_save :normalize_nip

  ADJECTIVES = %w[Alpha Beta Nova Quantum Dynamic Solid Bright Soft Mega Future Green Blue]
  NOUNS = %w[Solutions Systems Tech Group Studio Labs Partners Consulting Digital]
  SUFFIXES = ["Sp. z o.o.", "S.A.", "sp.k."]

  def generate_name
    "#{ADJECTIVES.sample} #{NOUNS.sample} #{SUFFIXES.sample}"
  end

  def self.generate_nip
    weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
    loop do
      digits = Array.new(9) {rand(0..9) }
      checksum = digits.zip(weights).sum { |d, w| d * w } % 11

      next if checksum == 10

      return (digits + [checksum]).join
    end
  end

  private

  def normalize_nip
    self.nip = nip.gsub(/[-\s]/, '') if nip.present?
  end
end
