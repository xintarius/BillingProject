namespace :invoices do
  desc 'delete unused and old invoices'
  task delete_invoices: :environment do
    invoices = Invoice.where(created_at: ..2.days.ago)
    puts "#{invoices.count} invoices deleted."
    invoices.delete_all
  end
end
