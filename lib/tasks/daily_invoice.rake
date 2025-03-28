namespace :daily_invoice do
  desc 'create daily invoices'
  task create_daily_invoice: :environment do
    puts 'Start searching for invoices...'
    start_day = Time.zone.now.beginning_of_day - 1.day
    end_day = Time.zone.now.end_of_day - 1.day
    invoices = Invoice.where(created_at: start_day..end_day)
    if invoices.count.positive?
      puts "Found #{invoices.count} invoices"
      count_brutto = invoices.sum(:brutto)
      count_netto = invoices.sum(:netto)
      DailyInvoice.create!(date: (Time.zone.today - 1.day), invoice_count: invoices.count, brutto_count: count_brutto,
                           netto_count: count_netto)
      puts '...daily invoice completed'
    else
      puts 'no invoices found'
    end
  end
end
