namespace :daily_invoice do
  desc 'create daily invoices'
  task create_daily_invoices: :environment do
    @logger.info('Start searching for invoices...')
    start_day = Time.zone.now.beginning_of_day - 1.day
    end_day = Time.zone.now.end_of_day - 1.day
    invoices = Invoice.where(created_at: start_day..end_day)

    if invoices.exists?
      grouped_invoices = invoices.select('user_id', 'COUNT(*) AS invoice_count',
                                         'SUM(brutto) AS brutto_sum', 'SUM(netto) AS netto_sum')
                                 .group(:user_id)
      @logger.info("Found #{invoices.count} invoices")

      grouped_invoices.each do |group_invoice|
        DailyInvoice.create!(date: (Time.zone.today - 1.day),
                             invoice_count: group_invoice.invoice_count,
                             brutto_count: group_invoice.brutto_sum,
                             netto_count: group_invoice.netto_sum,
                             user_id: group_invoice.user_id)
      end
      @logger.info('...daily invoice completed')
    else
      @logger.info('no invoices found')
    end
  end
end
