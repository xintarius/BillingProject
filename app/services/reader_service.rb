require 'rtesseract'
require 'pdf-reader'
# Reader service
class ReaderService
  def self.send_file(file, company_id)
    today = Time.zone.now.strftime('%Y%m%d')
    invoice = Invoice.where(company_id: company_id).order(created_at: :desc).first

    add_extension(file)
    extract_text_from_pdf(file) if add_extension(file) == 'pdf'
    extract_text_from_image(file) unless add_extension(file) == 'pdf'

    filename = "#{company_id.nip}_#{today}_#{invoice.id}.#{add_extension(file)}"
    upload_minio(filename, file, invoice)
  end

  def self.add_extension(file)
    case file.content_type
    when 'application/pdf' then 'pdf'
    when 'image/jpeg' then 'jpeg'
    when 'image/png' then 'png'
    else 'dat'
    end
  end

  def self.upload_minio(filename, file, invoice)
    file_path = "uploads/#{filename}"
    invoice.update!(file_path: file_path)
    MinioClient.upload(file_path, file)
  end

  def self.extract_text_from_image(file)
    RTesseract.new(file)
  end

  def self.extract_text_from_pdf(file)
    reader = PDF::Reader.new(file.tempfile)
    reader.pages.map(&:text).join("\n")
  end
end
