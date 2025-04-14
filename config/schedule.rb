set :output, 'log/cron.log'

every 1.day, at: '23:59' do
  runner 'daily_invoice.create_daily_invoices'
end

every 1.hour do
  runner 'invoices:check_invoices_status'
end