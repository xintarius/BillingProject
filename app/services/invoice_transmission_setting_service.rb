# invoice transmission setting service
class InvoiceTransmissionSettingService
  def initialize(invoice)
    @invoice = invoice
  end

  def change_sorted_data
    extracted = @invoice.sorted_data['extracted']

    ein = extracted['invoice_nr']
    eid = extracted['invoice_date']
    eun = extracted['user_nip']
    ecn = extracted['seller_nip']
    change_data(ein, eid, eun, ecn)
  end

  # variables write in short names ein, eid, eun and ecn
  # ein - extracted_invoice_nr
  # eid - extracted_invoice_date
  # eun - extracted_invoice_nip
  # ecn - extracted_company_nip
  def change_data(ein, eid, eun, ecn)
    e_inv_d = collect_date_format(eid)
    @invoice.update!(
      invoice_data_nr: ein[%r{[\d/-]+}],
      invoice_data_date: e_inv_d,
      user_nip_data: eun[/\b\d{10}\b/],
      company_nip_data: ecn[/\b\d{10}\b/]
    )
  end

  # get date depending on format
  def collect_date_format(date)
    date[/\d{4}-\d{2}-\d{2}/] || date[/\d{2}-\d{2}-\d{4}/]
  end
end
