require 'rtesseract'
require 'pdf-reader'
# Reader service
class ReaderService

  def self.send_file(file, company_id)
    today = Time.zone.now.strftime('%Y%m%d')
    invoice = Invoice.where(company_id: company_id).order(created_at: :desc).first
    extension = add_extension(file)
    filename = "#{company_id.nip}_#{today}_#{invoice.id}.#{extension}"

    if extension == 'pdf'
      extract_pdf_for_task(file)
    else
      file = ReaderService.convert_to_png_if_needed(file)
      extract_image_for_controller(file)
    end

    upload_minio(filename, file, invoice)
  end

  def self.convert_to_png_if_needed(file)
    mime = Marcel::MimeType.for(Pathname.new(file.path))

    return file if mime == 'image/png'

    image = Vips::Image.new_from_file(file.path, access: :sequential)

    tempfile = Tempfile.new(['converted', '.png'])
    image.write_to_file(tempfile.path)
    tempfile
  end

  def self.add_extension(file)
    case file.content_type
    when 'application/pdf' then 'pdf'
    when 'image/jpeg' then 'png'
    else 'no image type provided'
    end
  end

  def self.upload_minio(filename, file, invoice)
    file_path = "uploads/#{filename}"
    invoice.update!(file_path: file_path)
    MinioClient.upload(file_path, file)
  end

  def self.extract_image_for_controller(file)
    temp_path = '/tmp/temp_image.jpg'
    first_step(temp_path, reading_file(file))
  rescue StandardError => e
    puts "OCR image error: #{e.message}"
  end

  def self.extract_image_for_task(file, file_key)
    errors = []
    temp_path = "/tmp/temp_image_#{SecureRandom.hex(4)}.jpg"
    invoice = Invoice.where(file_path: file_key)
    invoice.find_by(ocr_image_phase: nil)
    first_step(temp_path, reading_file(file))
    first_step_text = read_text(invoice, temp_path, errors)
    puts "results after first step #{first_step_text}"
  rescue StandardError => e
    puts "OCR image error: #{e.message}"
  end

  def self.extract_pdf_for_task(file_path)
    reader = PDF::Reader.new(file_path)
    reader.pages.map(&:text).join("\n")
  end

  def self.regex_data(invoices, invoice, cleaned_text, errors)
    nip_regex(invoices, invoice, cleaned_text, errors)
    invoice_number_regex(invoices, invoice, cleaned_text, errors)
    total_amount_regex(invoices, invoice, cleaned_text, errors)
    date_regex(invoices, invoice, cleaned_text, errors)
  end

  def self.nip_regex(invoices, invoice, cleaned_text, errors)
    nip = cleaned_text.match(/(?:\D|^)(\d{10})(?:\D|$)|(\d{3}[-\s]?\d{3}[-\s]?\d{2}[-\s]?\d{2})/)
                      &.captures&.compact&.first
    errors << 'Brak nipu' if nip.nil?
    normal_nip = nip.gsub(/[-\s]/, '') if nip
    return unless normal_nip != invoices.company.nip

    errors << "NIP error #{normal_nip}, Base #{invoices.company.nip}"
    update_step(invoices, invoice, errors)
  end

  def self.update_step(invoices, invoice, errors)
    return unless invoice.find_by(ocr_image_phase: nil)

    invoices.update!(ocr_image_phase: 'first_step_completed')
    puts "first step completed, there are errors #{errors}, following to the second step"
  end

  def self.invoice_number_regex(invoices, invoice, cleaned_text, errors)
    invoice_number_match = cleaned_text.match(/FAKT.*?(\d{4})\D+FF\D+(\d{4})\D+(\d{4})/i)
    return unless invoice_number_match

    invoice_number = "#{invoice_number_match[1]}\\FF\\#{invoice_number_match[2]}\\#{invoice_number_match[3]}"
    return unless invoice_number != invoices.invoice_nr

    errors << "invoice number error: OCR '#{invoice_number}', Base '#{invoices.invoice_nr}'"

    update_step(invoices, invoice, errors)
  end

  def self.total_amount_regex(invoices, invoice, cleaned_text, errors)
    payment_type = if cleaned_text.include?('Gotówka:')
                     'Gotówka:'
                   else
                     cleaned_text.include?('Karta:')
                     'Karta:'
                   end

    total_amount_match = cleaned_text.match(/Zapłacono: #{payment_type} (\d+,\d{2})/)&.captures&.first
    base_amount_str = format('%.2f', invoices.brutto / 100.0).tr('.', ',')
    return unless total_amount_match != base_amount_str

    errors << "Cash error: OCR '#{total_amount_match}', Base: '#{invoices.brutto}'"

    update_step(invoices, invoice, errors)
  end

  def self.date_regex(invoices, invoice, cleaned_text, errors)
    date_match = cleaned_text.match(/Data: (\d{4}-\d{2}-\d{2})/)&.captures&.first
    return unless date_match && date_match != invoices.date.to_s

    errors << "Date error:'#{date_match}', Base: '#{invoices.date}'"

    update_step(invoices, invoice, errors)
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

  def self.first_step(temp_path, file_path)
    image = Vips::Image.new_from_file(file_path, access: :sequential)
    image = image.colourspace('b-w') # black-white color
                 .linear(1, -8) # linear is very important for receipts
                 .median(2) # remove noises
                 .resize(0.9)
                 .sharpen # edge sharpening
    image.write_to_file(temp_path, Q: 90)
  end

  def self.regex_and_errors(invoice, cleaned_text, errors, text)
    invoice.each do |invoices|
      next if %w[success failed].include?(invoices.invoice_status)

      regex_data(invoices, invoice, cleaned_text, errors)
      check_errors(invoices, errors)
      puts "🔍 OCR Result: #{text.strip}"
    end
  end

  def self.read_text(invoice, temp_path, errors)
    raw_text = RTesseract.new(temp_path,
                              lang: 'pol',
                              psm: 3, dpi: 300).to_s
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

    Tempfile.new(%w[ocr_image .png])
  end
end
