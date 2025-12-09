namespace :sort_data do

  desc 'Sorting parsed invoice data'
  task sort_invoices: :environment do
    Invoice.where.not(parsed_azure_invoice_data: nil).find_each do |invoice|
      parser = InvoiceParserService.new(invoice)
      sorted_data = parser.parse
      @logger.info("==== Faktura #{invoice.id} ====")
      invoice.update!(sorted_data: sorted_data)
    rescue StandardError => e
      @logger.error("Błąd przy fakturze #{invoice.id}: #{e.message}")
    end
  end
end
