require 'fileutils'
require 'mini_magick'
require_relative '../helpers/connection_helper'
namespace :invoice do

  desc 'Check invoices status'
  task check_invoices_status: :environment do
    @logger.info('Start checking documents status with initial status...')
    start_date = Time.zone.now.beginning_of_week
    end_date = Time.zone.now.end_of_week
    invoice = Invoice.where(invoice_status: 'initial', created_at: start_date..end_date, is_json_parsed: false, ocr_image_phase: nil)
                     .lock('FOR UPDATE SKIP LOCKED')
                     .pluck(:file_path)
    @logger.info("Found #{invoice.count} documents with initial status")
    @logger.info('Start calculate documents...')
    Invoice.equal_data(invoice)
  end

  desc 'Check and raise initial invoices status'
  task check_and_raise_invoice_status: :environment do
    @logger.info('Start checking invoices with initial status...')
    invoice = Invoice.where(invoice_status: 'initial')
    raise "Found #{invoice.count} documents with initial status after check" if invoice.count.positive?
  end

  desc 'delete unused and old invoices'
  task delete_invoices: :environment do
    invoices = Invoice.where(created_at: ..2.days.ago)
    @logger.info("#{invoices.count} invoices deleted.")
    invoices.delete_all
  end

  desc 'remove old invoices without data from storage'
  task delete_pdfs_from_storage: :environment do
    files = MinioClient.list_client_files
    invoices = Invoice.where(file_path: nil).pluck(:file_path)
    invoices_to_delete = invoices - files
    MinioClient.delete_file(invoices_to_delete) if invoices_to_delete.any?
  end
end
