every 1.day, at: '00:00 pm' do
  runner 'daily_invoice.create_daily_invoices'
end