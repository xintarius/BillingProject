require 'rtesseract'
require 'fileutils'
require 'mini_magick'
require_relative '../helpers/connection_helper'
namespace :invoices do

  desc 'Check invoices status'
  task check_invoices_status: :environment do
    Rails.logger.info 'Start checking documents status with initial status...'
    start_date = Time.zone.now.beginning_of_week
    end_date = Time.zone.now.end_of_week
    invoice = Invoice.where(invoice_status: 'initial', created_at: start_date..end_date).pluck(:file_path)
    Rails.logger.info "Found #{invoice.count} documents with initial status"
    Rails.logger.info 'Start calculate documents...'
    equal_data(invoice)
  end

  desc 'Check and raise initial invoices status'
  task check_and_raise_invoice_status: :environment do
    Rails.logger.info 'Start checking invoices with initial status...'
    invoice = Invoice.where(invoice_status: 'initial')
    raise "Found #{invoice.count} documents with initial status after check" if invoice.count.positive?
  end

  desc 'delete unused and old invoices'
  task delete_invoices: :environment do
    invoices = Invoice.where(created_at: ..2.days.ago)
    Rails.debugger.info "#{invoices.count} invoices deleted."
    invoices.delete_all
  end

  desc 'remove old pdfs from storage'
  task delete_pdfs_from_storage: :environment do
    files = MinioClient.list_client_files
    invoices = Invoice.where(file_path: nil).pluck(:file_path)
    invoices_to_delete = invoices - files
    MinioClient.delete_file(invoices_to_delete) if invoices_to_delete.any?
  end

  def equal_data(files)
    data_from_minio = MinioClient.list_files('uploads/')
    result = files & data_from_minio
    recognize_data(result)
  end

  def recognize_data(files)
    files.each do |file_key|
      ConnectionHelper.safe_push(OcrWorker, file_key)
    end
  end

  def download_from_minio(file_key)
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
