# invoice parser service
class InvoiceParserService
  def initialize(invoice)
    @invoice = invoice
    @lines = JSON.parse(invoice.parsed_azure_invoice_data).values.map(&:to_s)
  end

  def parse
    {
      extracted: {
        invoice_nr: extract_near(@invoice.invoice_nr),
        user_nip: extract_nip(@invoice.user_nip),
        invoice_date: match_date(@invoice.invoice_date),
        gross: match_amount(@invoice.brutto),
        invoice_number: extract_near(@invoice.invoice_nr),
        seller_nip: extract_near(@invoice.company&.nip),
      }
    }
  end

  def match_invoice_number
    @lines.any? do |line|
      normalize_text(line).include?(normalize_text(@invoice.invoice_nr))
    end
  end

  def extract_nip(nip)
    needle = nip.gsub(/\D/, '')

    @lines.find do |line|
      line.gsub(/\D/, '').include?(needle)
    end
  end

  def match_date(date)
    variants = [
      date.strftime('%Y-%m-%d'),
      date.strftime('%d-%m-%Y'),
      date.strftime('%d.%m.%Y'),
      date.strftime('%Y.%m.%d')
    ]

    @lines.find do |line|
      variants.find { |v| line.include?(v) }
    end
  end

  def match_amount(amount)
    normalized = format('%.2f', amount.to_f).tr('.', ',')

    @lines.find do |line|
      line.include?(normalized) || line.include?(normalized.tr(',', '.'))
    end
  end

  def extract_near(value)
    needle = normalize_text(value)

    @lines.find do |line|
      normalize_text(line).include?(needle)
    end
  end

  def normalize_text(text)
    text.to_s.downcase.gsub(/[^\p{L}\p{N}]/, '')
  end
end
