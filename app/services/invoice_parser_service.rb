class InvoiceParserService

  def initialize(invoice)
    @lines = JSON.parse(invoice.parsed_azure_invoice_data).values
  end

  def parse
    {
      invoice_number: extract_invoice_number,
      issue_date: extract_issue_date,
      seller: extract_seller,
      buyer: extract_buyer,
      items: extract_items,
      totals: extract_totals
    }
  end

  private

  def extract_invoice_number
    line = @lines.find { |l| l.include?('Numer:') || l =~ /nr\s*\d+/i }
    line&.sub(/Numer:\s*/, '')&.strip || line&.strip
  end

  def extract_issue_date
    issue_line = @lines.find { |l| l =~ /Data wystawienia[:]?/i }
    issue_date = issue_line&.sub(/Data wystawienia[:]?/, '')&.strip
    issue_date ||= @lines.find { |l| l =~ /\d{4}-\d{2}-\d{2}/ } # YYYY-MM-DD
    issue_date ||= @lines.find { |l| l =~ /\d{2}-\d{2}-\d{4}/ } # DD-MM-YYYY

    sale_line = @lines.find { |l| l =~ /Data sprzedaży[:]?/i }
    sale_date = sale_line&.sub(/Data sprzedaży[:]?/, '')&.strip
    sale_date ||= @lines.find { |l| l =~ /\d{4}-\d{2}-\d{2}/ } # fallback

    { issue_date: issue_date, sale_date: sale_date }

  end

  def extract_seller
    start_idx = @lines.find_index { |l| l.include?('Sprzedawca:') } || 0
    end_idx   = @lines.find_index { |l| l.include?('Nabywca:') } || (start_idx + 6)
    seller_lines = @lines[(start_idx + 1)...end_idx]

    {
      name: seller_lines[0],
      street: seller_lines[1],
      branch: seller_lines[2],
      street2: seller_lines[3],
      bdo: seller_lines[4]&.sub('BDO ', ''),
      nip: seller_lines[5]&.sub("NIP[:\s]*", '')&.strip
    }
  end

  def extract_buyer
    start_idx = @lines.find_index { |l| l.include?('Nabywca:') } || 0
    buyer_lines = @lines[(start_idx + 1)..-1]

    {
      name: buyer_lines[0],
      street: buyer_lines[1],
      city: buyer_lines[2],
      nip: buyer_lines[3]&.sub("NIP[:\s]*", '')&.strip
    }
  end

  def extract_items
    items = []

    @lines.each_with_index do |line, idx|
      next unless line.match?(/^[A-Z].*\d/) # heurystyka produktu

      net       = @lines[idx + 1] rescue nil
      vat_rate  = @lines[idx + 2] rescue nil
      vat_value = @lines[idx + 3] rescue nil
      gross     = @lines[idx + 4] rescue nil

      items << {
        name: line,
        net: net,
        vat_rate: vat_rate,
        vat_value: vat_value,
        gross: gross
      }
    end

    items
  end

  def extract_totals
    sum_idx = @lines.find_index { |l| l.include?('SUMA PLN') } || -1
    vat_idx = @lines.find_index { |l| l.include?('VAT') } || -1

    {
      net: (@lines[sum_idx - 2] rescue nil),
      vat: (@lines[vat_idx] rescue nil),
      gross: (@lines[sum_idx - 1] rescue nil)
    }
  end



end
