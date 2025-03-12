# invoice helper
module InvoiceHelper
  include SvgHelper
  def status_icon(status)
    case status
    when 'initial'
      icon('invoice_status_check')
    when 'fail'
      icon('invoice_status_fail')
    when 'success'
      icon('invoice_status_success')
    else '-'
    end
  end
end
