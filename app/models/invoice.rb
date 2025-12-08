# invoice model
class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :invoice_type
  belongs_to :invoice_vat_rate
  belongs_to :user
  attr_accessor :nip

  before_save :process_azure_json

  INVOICE_NUMBER_KEYS = %w[faktura_nr invoice_number number invoice_no invoice_nr fv].freeze

  def process_azure_json
    return if azure_invoice_raw_data.blank?

    raw = azure_invoice_raw_data
    lines = raw.dig('analyzeResult', 'pages', 0, 'lines') || []

    invoice_number = extract_from_lines(lines, /invoice\s*number/i)
    date           = extract_from_lines(lines, /date/i)
    total_amount   = extract_from_lines(lines, /total\s*amount/i)
    currency       = extract_from_lines(lines, /currency/i)
    customer_name  = extract_from_lines(lines, /customer\s*name/i)
    customer_address = extract_from_lines(lines, /customer\s*address/i)

    self.parsed_azure_invoice_data = {
      invoice_number: invoice_number,
      date: date,
      total_amount: total_amount,
      currency: currency,
      customer: {
        name: customer_name,
        address: customer_address
      }
    }
  rescue StandardError => e
    Rails.logger.error("Błąd parsowania Azure Invoice JSON: #{e.message}")
    self.parsed_azure_invoice_data = {}
  end

  def extract_from_lines(lines, regex)
    line = lines.find { |l| l['content'] =~ regex }
    return nil unless line

    if line['content'].include?(':')
      line['content'].split(':', 2).last.strip
    else
      line['content'].strip
    end
  end

  def self.equal_data(files)
    data_from_minio = MinioClient.list_files('uploads/')
    result = files & data_from_minio
    recognize_data(result)
  end

  def self.recognize_data(files)
    files.each do |file|
      ConnectionHelper.safe_push(OcrWorker, file)
    end
  end

  def self.download_from_minio(file_key)
    s3_client = MinioClient.client
    obj = s3_client.bucket(ENV.fetch('DEFAULT_BUCKET', nil)).object(file_key)
    local_path = File.join('tmp', File.basename(file_key))
    FileUtils.mkdir_p('tmp') unless File.directory?('tmp')
    File.binwrite(local_path, obj.get.body.read)
    Rails.debugger.info "File downloaded: #{local_path}"
    local_path
  rescue StandardError => e
    Rails.debugger.info "Error downloading #{file_key}: #{e.message}"
  end

end
