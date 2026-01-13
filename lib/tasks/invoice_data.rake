namespace :invoice_data do
  desc 'Process and normalize data in database'
  task process_invoice_data: :environment do
    @logger = Logger.new('log/invoice_data.log')
    @logger.info('start to process and setting properly data in invoices')
    invoices = Invoice.where.not(sorted_data: nil).find_each do |invoice|
      tr = InvoiceTransmissionSettingService.new(invoice)
      tr.change_sorted_data
    end
    @logger.info("Found #{invoices.count} invoices with not set data")
  rescue StandardError => e
    @logger.info("Error with the process settings #{e}")
  end
end
