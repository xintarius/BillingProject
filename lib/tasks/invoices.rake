require 'rtesseract'
require 'fileutils'
require 'mini_magick'
namespace :invoices do

  desc 'Check invoices status'
  task check_invoices_status: :environment do
    puts 'Start checking documents status with initial status...'
    start_date = Time.zone.now.beginning_of_week
    end_date = Time.zone.now.end_of_week
    invoice = Invoice.where(invoice_status: 'initial', created_at: start_date..end_date).pluck(:file_path)
    puts "Found #{invoice.count} documents with initial status"
    puts 'Start calculate documents...'
    equal_data(invoice)
  end

  desc 'delete unused and old invoices'
  task delete_invoices: :environment do
    invoices = Invoice.where(created_at: ..2.days.ago)
    puts "#{invoices.count} invoices deleted."
    invoices.delete_all
  end

  def equal_data(files)
    data_from_minio = MinioClient.list_files('uploads/')
    result = files & data_from_minio
    puts result
    recognize_data(result)
  end

  def recognize_data(files)
    files.each do |file_key|
      OcrWorker.perform_async(file_key)
    end
  end

  def download_from_minio(file_key)
    s3_client = MinioClient.connection
    obj = s3_client.bucket(ENV.fetch('DEFAULT_BUCKET', nil)).object(file_key)
    local_path = File.join('tmp', File.basename(file_key))
    FileUtils.mkdir_p('tmp') unless File.directory?('tmp')
    File.binwrite(local_path, obj.get.body.read)
    puts "File downloaded: #{local_path}"
    local_path
  rescue StandardError => e
    puts "Error downloading #{file_key}: #{e.message}"
  end
end
