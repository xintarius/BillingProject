# settlement service
class SettlementService

  def generate(start_date, end_date, user)
    csv_data = CSV.generate(col_sep: ';') do |csv|
    csv << %w[brutto netto vat]

    invoices = Invoice.joins('JOIN invoice_vat_rates vt ON invoices.invoice_vat_rate_id = vt.id')
                      .select('brutto', 'netto', 'vt.vat_rate as vat')

    invoices.each do |invoice|
      csv << [invoice.brutto, invoice.netto, invoice.vat]
    end
    end

    date = "#{start_date.to_date}_#{end_date.to_date}"
    name = "Raport_Miesięczny_#{date}"
    read_data = Base64.strict_encode64(csv_data)
    Export.create!(export_name: name, read_data: read_data, user_id: user.id)
  end
end
