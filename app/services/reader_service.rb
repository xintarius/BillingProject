require 'rtesseract'
require 'pdf-reader'
# Reader service
class ReaderService

  def self.send_file(file, company_id)
    today = Time.zone.now.strftime('%Y%m%d')
    invoice = Invoice.where(company_id: company_id).order(created_at: :desc).first
    add_extension(file)
    filename = "#{company_id.nip}_#{today}_#{invoice.id}.#{add_extension(file)}"
    extract_text_from_pdf(file) if add_extension(file) == 'pdf'
    extract_text_from_image(file, filename) unless add_extension(file) == 'pdf'

    upload_minio(filename, file, invoice)
  end

  def self.add_extension(file)
    case file.content_type
    when 'application/pdf' then 'pdf'
    when 'image/jpeg' then 'jpeg'
    when 'image/png' then 'png'
    else 'no image type provided'
    end
  end

  def self.upload_minio(filename, file, invoice)
    file_path = "uploads/#{filename}"
    invoice.update!(file_path: file_path)
    MinioClient.upload(file_path, file)
  end

  def self.extract_text_from_image(file, file_key)
    errors = []
    temp_path = '/tmp/temp_image.jpg'
    image_used(temp_path, reading_file(file))
    invoice = Invoice.where(file_path: file_key)
    read_text(invoice, temp_path, errors)
  rescue StandardError => e
    puts "OCR image error: #{e.message}"
  end

  def self.extract_text_from_pdf(file_path)
    reader = PDF::Reader.new(file_path)
    reader.pages.map(&:text).join("\n")
  end

  def self.regex_data(invoices, cleaned_text, errors)
    nip_regex(invoices, cleaned_text, errors)
    invoice_number_regex(invoices, cleaned_text, errors)
    total_amount_regex(invoices, cleaned_text, errors)
    date_regex(invoices, cleaned_text, errors)
  end

  def self.nip_regex(invoices, cleaned_text, errors)
    nip = cleaned_text.match(/(?:\D|^)(\d{10})(?:\D|$)|(\d{3}[-\s]?\d{3}[-\s]?\d{2}[-\s]?\d{2})/)
                      &.captures&.compact&.first
    errors << 'Brak nipu' if nip.nil?
    normal_nip = nip.gsub(/[-\s]/, '') if nip
    return unless normal_nip != invoices.company.nip

    errors << "NIP error #{normal_nip}, Base #{invoices.company.nip}"
  end

  def self.invoice_number_regex(invoices, cleaned_text, errors)
    invoice_number_match = cleaned_text.match(/FAKT.*?(\d{4})\D+FF\D+(\d{4})\D+(\d{4})/i)
    return unless invoice_number_match

    invoice_number = "#{invoice_number_match[1]}\\FF\\#{invoice_number_match[2]}\\#{invoice_number_match[3]}"
    return unless invoice_number != invoices.invoice_nr

    errors << "invoice number error: OCR '#{invoice_number}', Base '#{invoices.invoice_nr}'"
  end

  def self.total_amount_regex(invoices, cleaned_text, errors)
    total_amount_match = cleaned_text.match(/Brutto (\d+,\d{2})/)&.captures&.first
    return unless total_amount_match != invoices.brutto

    errors << "Cash error: OCR '#{total_amount_match}', Base: '#{invoices.brutto}'"
  end

  def self.date_regex(invoices, cleaned_text, errors)
    date_match = cleaned_text.match(/Data: (\d{4}-\d{2}-\d{2})/)&.captures&.first
    return unless date_match && date_match != invoices.date.to_s

    errors << "Date error:'#{date_match}', Base: '#{invoices.date}'"
  end

  def self.check_errors(invoices, errors)
    if errors.empty?
      invoices.update(invoice_status: 'success', description_error: nil)
      puts 'All data is checked'
    else
      invoices.update(invoice_status: 'failed', description_error: errors.to_json)
      puts 'Found errors:'
      errors.each { |e| puts " - #{e}" }
    end
  end

  def self.image_used(temp_path, file_path)
    image = Vips::Image.new_from_file(file_path, access: :sequential)
    image = image.colourspace('b-w') # black-white color
                 .median(2) # remove noises
                 .sharpen # edge sharpening
    image.write_to_file(temp_path, Q: 90)
  end

  def self.regex_and_errors(invoice, cleaned_text, errors, text)
    invoice.each do |invoices|
      next if %w[success failed].include?(invoices.invoice_status)

      regex_data(invoices, cleaned_text, errors)
      check_errors(invoices, errors)
      puts "🔍 OCR Result: #{text.strip}"
    end
  end

  def self.read_text(invoice, temp_path, errors)
    raw_text = RTesseract.new(temp_path,
                              lang: 'pol',
                              psm: 3).to_s
    text = raw_text.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
                   .gsub(/\p{C}/, '')
                   .gsub("\n", ' ')

    cleaned_text = text.gsub(/\s*\|\s*/, '\\')
                       .gsub(/\s+/, ' ')
                       .strip

    regex_and_errors(invoice, cleaned_text, errors, text)
  end

  def self.reading_file(file)
    return file if file.is_a?(String) && File.exist?(file)
    return file.path if file.respond_to?(:path) && File.exist?(file.path)

    Tempfile.new(%w[ocr_image .jpeg])
  end
end
